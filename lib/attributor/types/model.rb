module Attributor
  class Model < Hash
    # FIXME: this is not the way to fix this. Really we should add finalize! to Models.
    begin
      undef :timeout
      undef :format
      undef :test
    rescue
      nil
    end

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
      k = key_type
      ka = key_attribute

      v = value_type
      va = value_attribute

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
      define_reader(name)
      define_writer(name)
    end

    def self.define_reader(name)
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
          @contents[:#{name}]
        end
      RUBY
    end

    def self.define_writer(name)
      context = ['assignment', "of(#{name})"].freeze
      module_eval do
        define_method(name.to_s + '=') do |value|
          set(name, value, context: context)
        end
      end
    end

    def self.check_option!(name, value)
      case name
      when :identity
        raise AttributorException, "Invalid identity type #{value.inspect}" unless value.is_a?(::Symbol)
        :ok # FIXME: ... actually do something smart, that doesn't break lazy attribute creation
      when :reference
        :ok # FIXME: ... actually do something smart
      when :dsl_compiler
        :ok # FIXME: ... actually do something smart
      when :dsl_compiler_options
        :ok
      else
        super
      end
    end

    def self.generate_subcontext(context, subname)
      context + [subname]
    end

    def self.example(context = nil, **values)
      context ||= ["#{name || 'Struct'}-#{rand(10_000_000)}"]
      context = Array(context)

      if keys.any?
        result = new
        result.extend(ExampleMixin)

        result.lazy_attributes = example_contents(context, result, **values)
      else
        result = new
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
    def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
      raise AttributorException, 'validation conflict' if @validating
      @validating = true

      context = [context] if context.is_a? ::String
      # Use the common, underlying attribute validation of the hash (which will use our _get_attr)
      # to know how to retrieve a value from a model (instead of a hash)
      validate_keys(context)
    ensure
      @validating = false
    end

    def attributes
      @contents
    end

    def respond_to_missing?(name, *)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      return true if self.class.attributes.key?(attribute_name.to_sym)

      super
    end

    def method_missing(name, *args)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      if self.class.attributes.key?(attribute_name.to_sym)
        self.class.define_accessors(attribute_name)
        return __send__(name, *args)
      end

      super
    end

    def dump(context: Attributor::DEFAULT_ROOT_CONTEXT, **_opts)
      return CIRCULAR_REFERENCE_MARKER if @dumping
      @dumping = true

      attributes.each_with_object({}) do |(name, value), hash|
        attribute = self.class.attributes[name]

        # skip dumping undefined attributes
        unless attribute
          warn "WARNING: Trying to dump unknown attribute: #{name.inspect} with context: #{context.inspect}"
          next
        end

        hash[name.to_sym] = attribute.dump(value, context: context + [name], **_opts)
      end
    ensure
      @dumping = false
    end

    # This allows the splatting of these instances into method calls (top level hash conversion only)
    def to_hash
      @contents
    end
  end

  # Override the generic way to get a value from an instance (models need to call the method)
  def _get_attr(k)
    __send__(k)
  end    

end
