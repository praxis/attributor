module Attributor
  class Hash
    extend Forwardable

    include Container
    include Enumerable

    class << self
      attr_reader :key_type, :value_type, :options
    end

    @key_type = Object
    @value_type = Object
    @saved_blocks = []
    @options = {}
    @keys = {}


    def self.inherited(klass)
      k = self.key_type
      v = self.value_type

      klass.instance_eval do
        @saved_blocks = []
        @options = {}
        @keys = {}
        @key_type = k
        @value_type = v
      end
    end

    def self.keys(**options, &key_spec)
      if block_given?
        @saved_blocks << key_spec
        @options.merge!(options)
      elsif @saved_blocks.any?
        self.definition
      end
      @keys
    end

    def self.definition
      opts = {
        :key_type => @key_type,
        :value_type => @value_type
      }.merge(@options)

      blocks = @saved_blocks.shift(@saved_blocks.size)
      compiler = dsl_class.new(self, opts)
      compiler.parse(*blocks)
    end

    def self.dsl_class
      @options[:dsl_compiler] || DSLCompiler
    end

    def self.native_type
      self
    end

    def self.valid_type?(type)
      type.kind_of?(self) || type.kind_of?(::Hash)
    end

    # @example Hash.of(key: String, value: Integer)
    def self.of(key: Object, value: Object)
      if key
        resolved_key_type = Attributor.resolve_type(key)
        unless resolved_key_type.ancestors.include?(Attributor::Type)
          raise Attributor::AttributorException.new("Hashes only support key types that are Attributor::Types. Got #{resolved_key_type.name}")
        end
      end

      if value
        resolved_value_type = Attributor.resolve_type(value)
        unless resolved_value_type.ancestors.include?(Attributor::Type)
          raise Attributor::AttributorException.new("Hashes only support value types that are Attributor::Types. Got #{resolved_value_type.name}")
        end
      end

      Class.new(self) do
        @key_type = resolved_key_type
        @value_type = resolved_value_type
        @concrete = true
        @keys = {}
      end
    end


    def self.construct(constructor_block,  **options)
      return self if constructor_block.nil?

      unless @concrete
        return self.of(key:self.key_type, value: self.value_type)
        .construct(constructor_block,**options)
      end

      self.keys(options, &constructor_block)
      self
    end


    def self.example(context=nil, options: {})
      result = ::Hash.new
      # Let's not bother to generate any hash contents if there's absolutely no type defined
      return result if ( key_type == Object && value_type == Object )

      size = rand(3) + 1
      context ||= ["#{Hash}-#{rand(10000000)}"]

      size.times do |i|
        example_key = key_type.example(context + ["at(#{i})"])
        subcontext = context + ["at(#{example_key})"]
        result[example_key] = value_type.example(subcontext)
      end

      result
    end


    def self.dump(value, **opts)
      return nil if value.nil?
      return super if (@key_type == Object && @value_type == Object )

      value.each_with_object({}) do |(k,v),hash|
        k = key_type.dump(k,opts) if @key_type
        v = value_type.dump(v,opts) if @value_type
        hash[k] = v
      end
    end

    def self.check_option!(name, definition)
      case name
      when :key_type
        :ok
      when :value_type
        :ok
      when :reference
        :ok # FIXME ... actually do something smart
      else
        :unknown
      end
    end


    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      if value.nil?
        return nil
      elsif value.is_a?(::Hash)
        loaded_value = value
      elsif value.is_a?(::String)
        loaded_value = decode_json(value,context)
      else
        raise Attributor::IncompatibleTypeError, context: context, value_type: value.class, type: self
      end

      return self.from_hash(loaded_value,context) if self.keys.any?
      return self.new(loaded_value) if (key_type == Object && value_type == Object)

      loaded_value.each_with_object(self.new) do| (k, v), obj |
        obj[self.key_type.load(k,context)] = self.value_type.load(v,context)
      end

    end

    def self.generate_subcontext(context, key_name)
      context + ["get(#{key_name.inspect})"]
    end

    def self.from_hash(object,context)
      hash = self.new

      object.each do |k,v|
        hash_key = @key_type.load(k)

        hash_attribute = self.keys.fetch(hash_key) do
          raise AttributorException, "Unknown key received: #{k.inspect} while loading #{Attributor.humanize_context(context)}"
        end

        sub_context = self.generate_subcontext(context,hash_key)
        hash[hash_key] = hash_attribute.load(v, sub_context)
      end

      self.keys.each do |key_name, attribute|
        next if hash.key?(key_name)
        sub_context = self.generate_subcontext(context,key_name)
        hash[key_name] = attribute.load(nil, sub_context)
      end

      hash
    end


    def self.validate(object,context=Attributor::DEFAULT_ROOT_CONTEXT,_attribute)
      context = [context] if context.is_a? ::String

      unless object.kind_of?(self)
        raise ArgumentError, "#{self.name} can not validate object of type #{object.class.name} for #{Attributor.humanize_context(context)}."
      end

      object.validate(context)
    end



    # TODO: chance value_type and key_type to be attributes?
    # TODO: add a validate, which simply validates that the incoming keys and values are of the right type.
    #       Think about the format of the subcontexts to use: let's use .at(key.to_s)

    attr_reader :contents
    def_delegators :@contents, :[], :[]=, :each, :size, :keys, :key?

    def initialize(contents={})
      @contents = contents
    end

    def ==(other)
      contents == other || (other.respond_to?(:contents) ? contents == other.contents : false)
    end


    def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)
      context = [context] if context.is_a? ::String


      if self.class.keys.any?
        extra_keys = @contents.keys - self.class.keys.keys
        if extra_keys.any?
          return extra_keys.collect do |k|
            "#{Attributor.humanize_context(context)} can not have key: #{k.inspect}"
          end
        end

        self.class.keys.each_with_object(Array.new) do |(key, attribute), errors|
          sub_context = self.class.generate_subcontext(context,key)

          value = @contents[key]

          if value.respond_to?(:validating) # really, it's a thing with sub-attributes
            next if value.validating
          end

          errors.push *attribute.validate(value, sub_context)
        end
      else
        @contents.each_with_object(Array.new) do |(key, value), errors|
          sub_context = self.class.generate_subcontext(context,key)
          errors.push *@key_type.validate(key, sub_context) unless @key_type == Attributor::Object
          errors.push *@value_type.validate(value, sub_context)  unless @value_type == Attributor::Object
        end
      end
    end

    def dump(*args)
      # TODO
    end

  end

end
