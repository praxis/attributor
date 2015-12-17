module Attributor
  class Model < Hash

    # FIXME: this is not the way to fix this. Really we should add finalize! to Models.
    undef :timeout
    undef :format
    undef :test rescue nil

    if RUBY_ENGINE =~ /^jruby/
      # We are "forced" to require it here (in case hasn't been yet) to make sure the added methods have been applied
      require 'java'
      # Only to then delete them, to make sure we don't have them clashing with any attributes
      undef java, javax, org, com
    end

    # Remove undesired methods inherited from Hash
    undef :size
    undef :keys
    undef :values
    undef :has_key?

    @key_type = Symbol
    @value_type = Object

    @key_attribute = Attribute.new(@key_type)
    @value_attribute = Attribute.new(@value_type)


    def self.inherited(klass)
      k = self.key_type
      ka = self.key_attribute

      v = self.value_type
      va = self.value_attribute

      klass.instance_eval do
        @saved_blocks = []
        @options = {}
        @keys = {}
        @key_type = k
        @value_type = v

        @key_attribute = ka
        @value_attribute = va

        @requirements = []
        @error = false
      end
    end

    # Define accessors for attribute of given name.
    #
    # @param name [::Symbol] attribute name
    #
    def self.define_accessors(name)
      name = name.to_sym
      self.define_reader(name)
      self.define_writer(name)
    end

    def self.define_reader(name)
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
          @contents[:#{name}]
        end
      RUBY
    end


    def self.define_writer(name)
      context = ["assignment","of(#{name})"].freeze
      module_eval do
        define_method(name.to_s + "=") do |value|
          self.set(name, value, context: context)
        end
      end
    end

    def self.check_option!(name, value)
      case name
      when :identity
        raise AttributorException, "Invalid identity type #{value.inspect}" unless value.kind_of?(::Symbol)
        :ok # FIXME ... actually do something smart, that doesn't break lazy attribute creation
      when :reference
        :ok # FIXME ... actually do something smart
      when :dsl_compiler
        :ok # FIXME ... actually do something smart
      when :dsl_compiler_options
        :ok
      else
        super
      end
    end

    def self.generate_subcontext(context, subname)
      context + [subname]
    end

    def self.example(context=nil, **values)
      context ||= ["#{self.name || 'Struct'}-#{rand(10000000)}"]
      context = Array(context)

      if self.keys.any?
        result = self.new
        result.extend(ExampleMixin)

        result.lazy_attributes = self.example_contents(context, result, values)
      else
        result = self.new
      end
      result
    end

    def initialize(data = nil)
      if data
        loaded = self.class.load(data)
        @contents = loaded.attributes
      else
        @contents = {}
      end
    end


    # TODO: memoize validation results here, but only after rejiggering how we store the context.
    #       Two calls to validate() with different contexts should return get the same errors,
    #       but with their respective contexts.
    def validate(context=Attributor::DEFAULT_ROOT_CONTEXT)

      raise AttributorException, "validation conflict" if @validating
      @validating = true

      context = [context] if context.is_a? ::String

      ret = self.class.attributes.each_with_object(Array.new) do |(sub_attribute_name, sub_attribute), errors|
        sub_context = self.class.generate_subcontext(context,sub_attribute_name)

        value = self.__send__(sub_attribute_name)
        if value.respond_to?(:validating) # really, it's a thing with sub-attributes
          next if value.validating
        end

        errors.push *sub_attribute.validate(value, sub_context)
      end
      self.class.requirements.each_with_object(ret) do |req, errors|
        validation_errors = req.validate( @contents , context)
        errors.push *validation_errors unless validation_errors.empty?
      end
      ret
    ensure
      @validating = false
    end


    def attributes
      @contents
    end


    def respond_to_missing?(name,*)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      return true if self.class.attributes.key?(attribute_name.to_sym)

      super
    end


    def method_missing(name, *args)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      if self.class.attributes.has_key?(attribute_name.to_sym)
        self.class.define_accessors(attribute_name)
        return self.__send__(name, *args)
      end

      super
    end


    def dump(context: Attributor::DEFAULT_ROOT_CONTEXT, **opts)
      return CIRCULAR_REFERENCE_MARKER if @dumping
      @dumping = true

      self.attributes.each_with_object({}) do |(name, value), hash|
        attribute = self.class.attributes[name]

        # skip dumping undefined attributes
        unless attribute
          warn "WARNING: Trying to dump unknown attribute: #{name.inspect} with context: #{context.inspect}"
          next
        end

        hash[name.to_sym] = attribute.dump(value, context: context + [name] )
      end
    ensure
      @dumping = false
    end

  end

end
