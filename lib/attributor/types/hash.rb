module Attributor
  class InvalidDefinition < StandardError
    def initialize(type, cause)
      type_name = if type.name
                    type.name
                  else
                    type.inspect
                  end

      msg = "Structure definition for type #{type_name} is invalid. The following exception has occurred: #{cause.inspect}"
      super(msg)
      @cause = cause
    end

    attr_reader :cause
  end

  class Hash
    MAX_EXAMPLE_DEPTH = 10
    CIRCULAR_REFERENCE_MARKER = '...'.freeze

    include Container
    include Enumerable
    include Dumpable

    class << self
      attr_reader :key_type, :value_type, :options
      attr_reader :value_attribute
      attr_reader :key_attribute
      attr_reader :insensitive_map
      attr_accessor :extra_keys
      attr_reader :requirements
      attr_reader :cached_defaults
    end

    @key_type = Object
    @value_type = Object

    @key_attribute = Attribute.new(@key_type)
    @value_attribute = Attribute.new(@value_type)

    @error = false
    @requirements = []
    @cached_defaults = {}

    def self.slice!(*keys)
      missing_keys = keys - @keys.keys
      raise AttributorException, "Cannot slice! this type, because it does not contain one or more of the requested keys: #{missing_keys}" unless missing_keys.empty?
      instance_variable_set(:@keys, @keys.slice(*keys))
      self
    end

    def self.key_type=(key_type)
      @key_type = Attributor.resolve_type(key_type)
      @key_attribute = Attribute.new(@key_type)
      @concrete = true
    end

    def self.value_type=(value_type)
      @value_type = Attributor.resolve_type(value_type)
      @value_attribute = Attribute.new(@value_type)
      @concrete = true
    end

    def self.family
      'hash'
    end

    @saved_blocks = []
    @options = { allow_extra: false }
    @keys = {}

    def self.inherited(klass)
      k = key_type
      v = value_type

      klass.instance_eval do
        @saved_blocks = []
        @options = { allow_extra: false }
        @keys = {}
        @key_type = k
        @value_type = v
        @key_attribute = Attribute.new(@key_type)
        @value_attribute = Attribute.new(@value_type)
        @requirements = []
        @cached_defaults = {}
        @error = false
      end
    end

    def self.attributes(**options, &key_spec)
      raise @error if @error

      keys(**options, &key_spec)
    end

    def self.keys(**options, &key_spec)
      raise @error if @error

      if block_given?
        @saved_blocks << key_spec
        @options.merge!(options)
      elsif @saved_blocks.any?
        definition
      end
      @keys
    end

    def self.requirements
      if @saved_blocks.any?
        definition
      end
      @requirements
    end

    def self.definition
      opts = {
        key_type: @key_type,
        value_type: @value_type
      }.merge(@options)

      blocks = @saved_blocks.shift(@saved_blocks.size)
      compiler = dsl_class.new(self, **opts)
      compiler.parse(*blocks)

      if opts[:case_insensitive_load] == true
        @insensitive_map = keys.keys.each_with_object({}) do |k, map|
          map[k.downcase] = k
        end
      end
    rescue => e
      @error = InvalidDefinition.new(self, e)
      raise
    end

    def self.dsl_class
      @options[:dsl_compiler] || HashDSLCompiler
    end

    def self.native_type
      self
    end

    def self.valid_type?(type)
      type.is_a?(self) || type.is_a?(::Hash)
    end

    # @example Hash.of(key: String, value: Integer)
    def self.of(key: @key_type, value: @value_type)
      ::Class.new(self) do
        self.key_type = key
        self.value_type = value
        @keys = {}
      end
    end

    def self.constructable?
      true
    end

    def self.add_requirement(req)
      @requirements << req
      return unless req.attr_names
      non_existing = req.attr_names - attributes.keys
      unless non_existing.empty?
        raise "Invalid attribute name(s) found (#{non_existing.join(', ')}) when defining a requirement of type #{req.type} for #{Attributor.type_name(self)} ." \
              "The only existing attributes are #{attributes.keys}"
      end
    end

    def self.construct(constructor_block, **options)
      return self if constructor_block.nil?

      unless @concrete
        return of(key: key_type, value: value_type)
               .construct(constructor_block, **options)
      end

      if options[:case_insensitive_load] && !(key_type <= String)
        raise Attributor::AttributorException, ":case_insensitive_load may not be used with keys of type #{key_type.name}"
      end

      keys(**options, &constructor_block)
      self
    end



    def self.example_contents(context, parent, **values)
      hash = ::Hash.new
      example_depth = context.size
      # Be smart about what attributes to use for the example: i.e. have into account complex requirements
      # that might have been defined in the hash like at_most(1).of ..., exactly(2).of ...etc.
      # But play it safe and default to the previous behavior in case there is any error processing them
      # ( that is until the SmartAttributeSelector class isn't fully tested and ready for prime time)
      begin
        stack = SmartAttributeSelector.new( requirements.map(&:describe), keys.keys , values)
        selected = stack.process
      rescue => e
        selected = keys.keys
      end

      keys.select{|n,attr| selected.include? n}.each do |sub_attribute_name, sub_attribute|
        if sub_attribute.attributes
          # TODO: add option to raise an exception in this case?
          next if example_depth > MAX_EXAMPLE_DEPTH
        end

        sub_context = generate_subcontext(context, sub_attribute_name)
        block = proc do
          value = values.fetch(sub_attribute_name) do
            sub_attribute.example(sub_context, parent: parent)
          end
          sub_attribute.load(value, sub_context)
        end

        hash[sub_attribute_name] = block
      end

      hash
    end

    def self.example(context = nil, **values)
      return new if key_type == Object && value_type == Object && keys.empty?

      context ||= ["#{Hash}-#{rand(10_000_000)}"]
      context = Array(context)

      if keys.any?
        result = new
        result.extend(ExampleMixin)

        result.lazy_attributes = example_contents(context, result, **values)
      else
        hash = ::Hash.new

        (rand(3) + 1).times do |i|
          example_key = key_type.example(context + ["at(#{i})"])
          subcontext = context + ["at(#{example_key})"]
          hash[example_key] = value_type.example(subcontext)
        end

        result = new(hash)
      end

      result
    end

    def self.dump(value, **opts)
      if (loaded = load(value))
        loaded.dump(**opts)
      end
    end

    def self.check_option!(name, _definition)
      case name
      when :reference
        :ok # FIXME: ... actually do something smart
      when :dsl_compiler
        :ok
      when :case_insensitive_load
        unless key_type <= String
          raise Attributor::AttributorException, ":case_insensitive_load may not be used with keys of type #{key_type.name}"
        end
        :ok
      when :allow_extra
        :ok
      else
        :unknown
      end
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, recurse: false, **_options)

      return value if value.is_a?(self)
      return nil if value.nil? && !recurse

      context = Array(context)
      loaded_value = self.parse(value, context)

      return from_hash(loaded_value, context, recurse: recurse) if keys.any?
      load_generic(loaded_value, context)
    end

    def self.parse(value, context)
      if value.nil?
        {}
      elsif value.is_a?(Attributor::Hash)
        value.contents
      elsif value.is_a?(::Hash)
        value
      elsif value.is_a?(::String)
        decode_json(value, context)
      elsif value.respond_to?(:to_h)
        value.to_h
      elsif value.respond_to?(:to_hash) # Deprecate this in lieu of to_h only?
        value.to_hash
      else
        raise Attributor::IncompatibleTypeError.new(context: context, value_type: value.class, type: self)
      end
    end

    def self.load_generic(value, context)
      return new(value) if key_type == Object && value_type == Object

      value.each_with_object(new) do |(k, v), obj|
        obj[key_type.load(k, context)] = value_type.load(v, context)
      end
    end

    def self.generate_subcontext(context, key_name)
      context + ["key(#{key_name.inspect})"]
    end

    def to_h
      Attributor.recursive_to_h(@contents)
    end

    def generate_subcontext(context, key_name)
      self.class.generate_subcontext(context, key_name)
    end

    def get(key, context: generate_subcontext(Attributor::DEFAULT_ROOT_CONTEXT, key))
      key = self.class.key_attribute.load(key, context)

      return self.get_generic(key, context) if self.class.keys.empty?
      value = @contents[key]

      # FIXME: getting an unset value here should not force it in the hash
      if (attribute = self.class.keys[key])
        loaded_value = attribute.load(value, context)
        return nil if loaded_value.nil?
        return self[key] = loaded_value
      end

      if self.class.options[:case_insensitive_load]
        key = self.class.insensitive_map[key.downcase]
        return get(key, context: context)
      end

      if self.class.options[:allow_extra]
        return @contents[key] = self.class.value_attribute.load(value, context) if self.class.extra_keys.nil?
        extra_keys_key = self.class.extra_keys

        if @contents.key? extra_keys_key
          return @contents[extra_keys_key].get(key, context: context)
        end

      end

      raise LoadError, "Unknown key received: #{key.inspect} for #{Attributor.humanize_context(context)}"
    end

    def get_generic(key, context)
      if @contents.key? key
        value = @contents[key]
        loaded_value = value_attribute.load(value, context)
        return self[key] = loaded_value
      elsif self.class.options[:case_insensitive_load]
        key = key.downcase
        @contents.each do |k, _v|
          return get(key, context: context) if key == k.downcase
        end
      end
      nil
    end

    def set(key, value, context: generate_subcontext(Attributor::DEFAULT_ROOT_CONTEXT, key), recurse: false)
      key = self.class.key_attribute.load(key, context)

      if self.class.keys.empty?
        return self[key] = self.class.value_attribute.load(value, context)
      end

      if (attribute = self.class.keys[key])
        return self[key] = attribute.load(value, context, recurse: recurse)
      end

      if self.class.options[:case_insensitive_load]
        key = self.class.insensitive_map[key.downcase]
        return set(key, value, context: context)
      end

      if self.class.options[:allow_extra]
        return self[key] = self.class.value_attribute.load(value, context) if self.class.extra_keys.nil?

        extra_keys_key = self.class.extra_keys

        unless @contents.key? extra_keys_key
          extra_keys_value = self.class.keys[extra_keys_key].load({})
          @contents[extra_keys_key] = extra_keys_value
        end

        return self[extra_keys_key].set(key, value, context: context)

      end

      raise LoadError, "Unknown key received: #{key.inspect} while loading #{Attributor.humanize_context(context)}"
    end

    def self.from_hash(object, context, recurse: false)
      hash = new

      # if the hash definition includes named extra keys, initialize
      # its value from the object in case it provides some already.
      # this is to ensure it exists when we handle any extra keys
      # that may exist in the object later
      if extra_keys
        sub_context = generate_subcontext(context, extra_keys)
        v = object.fetch(extra_keys, {})
        hash.set(extra_keys, v, context: sub_context, recurse: recurse)
      end

      object.each do |k, val|
        next if k == extra_keys

        sub_context = generate_subcontext(context, k)
        hash.set(k, val, context: sub_context, recurse: recurse)
      end

      # handle default values for missing keys
      keys.each do |key_name, attribute|
        next if hash.key?(key_name)

        # Cache default values to avoid a whole loading call for the attribute
        default = if @cached_defaults.key?(key_name)
          @cached_defaults[key_name]
        else
          sub_context = generate_subcontext(context, key_name)
          @cached_defaults[key_name] = attribute.load(nil, sub_context, recurse: recurse)
        end
        hash[key_name] = default unless default.nil?
      end
      hash
    end

    

    def self.validate(object, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute)
      context = [context] if context.is_a? ::String

      unless object.is_a?(self)
        raise ArgumentError, "#{name} can not validate object of type #{object.class.name} for #{Attributor.humanize_context(context)}."
      end
      object.validate(context)
    end

    def self.describe(shallow = false, example: nil)
      hash = super(shallow)

      hash[:key] = { type: key_type.describe(true) } if key_type

      if keys.any?
        # Spit keys if it's the root or if it's an anonymous structures
        if ( !shallow || self.name == nil)
          required_names_from_attr = []
          # FIXME: change to :keys when the praxis doc browser supports displaying those
          hash[:attributes] = self.keys.each_with_object({}) do |(sub_name, sub_attribute), sub_attributes|
            required_names_from_attr << sub_name if sub_attribute.options[:required] == true
            sub_example = example.get(sub_name) if example
            sub_attributes[sub_name] = sub_attribute.describe(true, example: sub_example)
          end
          hash[:requirements] = requirements.each_with_object([]) do |req, list|
            described_req = req.describe(shallow)
            if described_req[:type] == :all
              # Add the names of the attributes that have the required flag too
              described_req[:attributes] |= required_names_from_attr
              required_names_from_attr = []
            end
            list << described_req
          end
          # Make sure we create an :all requirement, if there wasn't one so we can add the required: true attributes
          unless required_names_from_attr.empty?
            hash[:requirements] << {type: :all, attributes: required_names_from_attr }
          end
        end
      else
        hash[:value] = { type: value_type.describe(true) }
        hash[:example] = example if example
        hash[:attributes] = {}
      end

      hash
    end

    def self.as_json_schema( shallow: false, example: nil, attribute_options: {} )
      hash = super
      opts = self.options.merge( attribute_options )

      if key_type
        hash[:'x-key_type'] = key_type.as_json_schema
      end

      if self.keys.any?
        # Spit keys if it's the root or if it's an anonymous structures
        if ( !shallow || self.name == nil)
          required_names_from_attr = []
          # FIXME: change to :keys when the praxis doc browser supports displaying those
          hash[:properties] = self.keys.each_with_object({}) do |(sub_name, sub_attribute), sub_attributes|
            required_names_from_attr << sub_name if sub_attribute.options[:required] == true
            sub_example = example.get(sub_name) if example
            sub_attributes[sub_name] = sub_attribute.as_json_schema(shallow: true, example: sub_example)
          end

          # Expose the more complex requirements to in the x-tended attribute
          extended_requirements = self.requirements.each_with_object([]) do |req, list|
            described_req = req.describe(shallow)
            if described_req[:type] == :all
              # Add the names of the attributes that have the required flag too
              described_req[:attributes] |= required_names_from_attr
              required_names_from_attr = []
            end
            list << described_req
          end
          all = extended_requirements.find{|r| r[:type] == :all }
          if ( all && !all[:attributes].empty? )
            hash[:required] = all[:attributes]
          end
          hash[:'x-requirements'] = extended_requirements unless extended_requirements.empty?
        end
      else
        hash[:'x-value_type'] = value_type.as_json_schema(shallow:true)
      end

      if opts[:allow_extra]
        hash[:additionalProperties] = if value_type == Attributor::Object
          true
        else
          value_type.as_json_schema(shallow: true)
        end
      end
      # TODO: minProperties and maxProperties and patternProperties
      hash
    end

    def self.json_schema_type
      :object
    end

    # TODO: Think about the format of the subcontexts to use: let's use .at(key.to_s)
    attr_reader :contents

    def [](k)
      @contents[k]
    end

    def _get_attr(k)
      self[k]
    end

    def []=(k, v)
      @contents[k] = v
    end

    def each(&block)
      @contents.each(&block)
    end

    alias each_pair each

    def size
      @contents.size
    end

    def keys
      @contents.keys
    end

    def values
      @contents.values
    end

    def empty?
      @contents.empty?
    end

    def key?(k)
      @contents.key?(k)
    end
    alias has_key? key?

    def merge(h)
      case h
      when self.class
        self.class.new(contents.merge(h.contents))
      when Attributor::Hash
        source_key_type = self.class.key_type
        source_value_type = self.class.value_type
        # Allow merging hashes, but we'll need to coerce keys and/or values if they aren't the same type
        coerced_contents = h.contents.each_with_object({}) do |(key, val), object|
          k = (source_key_type && !k.is_a?(source_key_type)) ? source_key_type.load(key) : key
          v = (source_value_type && !k.is_a?(source_value_type)) ? source_value_type.load(val) : val
          object[k] = v
        end
        self.class.new(contents.merge(coerced_contents))
      else
        raise TypeError, "no implicit conversion of #{h.class} into Attributor::Hash"
      end
    end

    def delete(key)
      @contents.delete(key)
    end

    attr_reader :validating, :dumping

    def initialize(contents = {})
      @validating = false
      @dumping = false

      @contents = contents
    end

    def key_type
      self.class.key_type
    end

    def value_type
      self.class.value_type
    end

    def key_attribute
      self.class.key_attribute
    end

    def value_attribute
      self.class.value_attribute
    end

    def ==(other)
      contents == other || (other.respond_to?(:contents) ? contents == other.contents : false)
    end

    def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
      @validating = true
      context = [context] if context.is_a? ::String

      if self.class.keys.any?
        extra_keys = @contents.keys - self.class.keys.keys
        if extra_keys.any? && !self.class.options[:allow_extra]
          return extra_keys.collect do |k|
            "#{Attributor.humanize_context(context)} can not have key: #{k.inspect}"
          end
        end
        self.validate_keys(context)
      else
        self.validate_generic(context)
      end
    ensure
      @validating = false      
    end

    def validate_keys(context)
      errors = []
      keys_provided = []

      self.class.keys.each do |key, attribute|
        sub_context = self.class.generate_subcontext(context, key)

        value = _get_attr(key)
        keys_provided << key if @contents.key?(key)

        if value.respond_to?(:validating) # really, it's a thing with sub-attributes
          next if value.validating
        end
        # Isn't this handled by the requirements validation? NO! we might want to combine
        if attribute.options[:required] && !@contents.key?(key)
          errors.concat ["Attribute #{Attributor.humanize_context(sub_context)} is required."]
        end
        if @contents[key].nil?
          if !Attribute.nullable_attribute?(attribute.options) && @contents.key?(key)
            errors.concat ["Attribute #{Attributor.humanize_context(sub_context)} is not nullable."]
          end
          # No need to validate the attribute further if the key wasn't passed...(or we would get nullable errors etc..cause the attribute has no
          # context if its containing key was even passed (and there might not be a containing key for a top level attribute anyways))
        else
          errors.concat attribute.validate(value, sub_context)
        end
      end
      self.class.requirements.each do |requirement|
        validation_errors = requirement.validate(keys_provided, context)
        errors.concat(validation_errors) unless validation_errors.empty?
      end
      errors
    end

    def validate_generic(context)
      @contents.each_with_object([]) do |(key, value), errors|
        # FIXME: the sub contexts and error messages don't really make sense here
        unless key_type == Attributor::Object
          sub_context = context + ["key(#{key.inspect})"]
          errors.concat key_attribute.validate(key, sub_context)
        end

        unless value_type == Attributor::Object
          sub_context = context + ["value(#{value.inspect})"]
        errors.concat value_attribute.validate(value, sub_context)
        end
      end
    end

    def dump(**opts)
      return CIRCULAR_REFERENCE_MARKER if @dumping
      @dumping = true

      contents.each_with_object({}) do |(k, v), hash|
        k = key_attribute.dump(k, **opts)

        v = if (attribute_for_value = self.class.keys[k])
              attribute_for_value.dump(v, **opts)
            else
              value_attribute.dump(v, **opts)
            end

        hash[k] = v
      end
    ensure
      @dumping = false
    end
  end
end
