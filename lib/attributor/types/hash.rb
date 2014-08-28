module Attributor
  class Hash
    extend Forwardable

    include Container
    include Enumerable

    class << self
      attr_reader :key_type, :value_type, :options
      attr_reader :value_attribute
      attr_reader :key_attribute
    end

    @key_type = Object
    @value_type = Object
    

    @key_attribute = Attribute.new(@key_type)
    @value_attribute = Attribute.new(@value_type)

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
        @key_attribute = Attribute.new(@key_type)
        @value_attribute = Attribute.new(@value_type)
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
    def self.of(key: @key_type, value: @value_type)
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
        
        @key_attribute = Attribute.new(@key_type)
        @value_attribute = Attribute.new(@value_type)
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
      return self.new if (key_type == Object && value_type == Object)

      hash = ::Hash.new
      context ||= ["#{Hash}-#{rand(10000000)}"]
      context = Array(context)

      if self.keys.any?
        self.keys.each do |sub_name, sub_attribute|
          subcontext = context + ["at(#{sub_name})"]
          hash[sub_name] = sub_attribute.example(subcontext)
        end
      else
        size = rand(3) + 1
        
        size.times do |i|
          example_key = key_type.example(context + ["at(#{i})"])
          subcontext = context + ["at(#{example_key})"]
          hash[example_key] = value_type.example(subcontext)
        end
      end

      self.new(hash)
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
      elsif value.is_a?(self)
        return value
      elsif value.kind_of?(Attributor::Hash)
        loaded_value = value.contents
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

    def self.describe(shallow=false)
      hash = super

      if key_type
        hash[:key] = {type: key_type.describe}
      end

      if self.keys.any?
        # Spit keys if it's the root or if it's an anonymous structures
        if ( !shallow || self.name == nil) && self.keys.any?
          # FIXME: change to :keys when the praxis doc browser supports displaying those. or josep's demo is over.
          hash[:keys] = self.keys.each_with_object({}) do |(sub_name, sub_attribute), sub_attributes|
            sub_attributes[sub_name] = sub_attribute.describe(true)
          end
        end
      else
        hash[:value] = {type: value_type.describe(true)}
      end

      hash
    end

    # TODO: chance value_type and key_type to be attributes?
    # TODO: add a validate, which simply validates that the incoming keys and values are of the right type.
    #       Think about the format of the subcontexts to use: let's use .at(key.to_s)
    attr_reader :contents
    def_delegators :@contents, :[], :[]=, :each, :size, :keys, :key?, :values, :empty?

    def initialize(contents={})
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
          # FIXME: the sub contexts and error messages don't really make sense here
          unless key_type == Attributor::Object
            sub_context = context + ["key(#{key.inspect})"]
            errors.push *key_attribute.validate(key, sub_context) 
          end            

          unless value_type == Attributor::Object
            sub_context = context + ["value(#{value.inspect})"]
            errors.push *value_attribute.validate(value, sub_context)  
          end
        end
      end
    end

    def dump(*args)
      @contents.each_with_object(::Hash.new) do |(k,v), hash|
        hash[k] = self.class.value_type.dump(v)
      end
    end

  end

end
