# TODO: profile keys for attributes, test as frozen strings

module Attributor
  class FakeParent < ::BasicObject
    def respond_to_missing?(_method_name)
      true
    end

    def method_missing(name, *_args) # rubocop:disable Style/MethodMissing
      ::Kernel.warn "Warning, you have tried to access the '#{name}' method of the 'parent' argument of a Proc-defined :default values." \
                    "Those Procs should completely ignore the 'parent' attribute for the moment as it will be set to an " \
                    'instance of a useless class (until the framework can provide such functionality)'
      nil
    end

    def class
      FakeParent
    end
  end

  # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
  # TODO: should this be a mixin since it is an abstract class?
  class Attribute
    attr_reader :type, :options

    @custom_options = {}

    class << self
      attr_accessor :custom_options
    end    

    def self.custom_option(name, attr_type, options = {}, &block)
      if TOP_LEVEL_OPTIONS.include?(name) || INTERNAL_OPTIONS.include?(name)
        raise ArgumentError, "can not define custom_option with name #{name.inspect}, it is reserved by Attributor"
      end
      self.custom_options[name] = Attributor::Attribute.new(attr_type, options, &block)
    end

    # @options: metadata about the attribute
    # @block: code definition for struct attributes (nil for predefined types or leaf/simple types)
    def initialize(type, options = {}, &block)
      @type = Attributor.resolve_type(type, options, block)
      @options = @type.respond_to?(:options) ?  @type.options.merge(options) : options

      check_options!
    end

    def duplicate(type: nil, options: nil)
      clone.tap do |cloned|
        cloned.instance_variable_set(:@type, type) if type
        cloned.instance_variable_set(:@options, options) if options
      end
    end

    def ==(other)
      raise ArgumentError, "can not compare Attribute with #{other.class.name}" unless other.is_a?(Attribute)

      type == other.type &&
        options == other.options
    end

    def parse(value, context = Attributor::DEFAULT_ROOT_CONTEXT)
      object = load(value, context)

      errors = validate(object, context)
      [object, errors]
    end

    def load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      value = type.load(value, context, **options)

      if value.nil? && self.options.key?(:default)
        defined_val = self.options[:default]
        val = case defined_val
              when ::Proc
                fake_parent = FakeParent.new
                # TODO: we can only support "context" as a parameter to the proc for now, since we don't have the parent...
                if defined_val.arity == 2
                  defined_val.call(fake_parent, context)
                elsif defined_val.arity == 1
                  defined_val.call(fake_parent)
                else
                  defined_val.call
                end
              else
                defined_val
              end
        value = val # Need to load?
      end

      value
    rescue AttributorException, NameError
      raise
    rescue => e
      raise Attributor::LoadError, "Error loading attribute #{Attributor.humanize_context(context)} of type #{type.name} from value #{Attributor.errorize_value(value)}\n#{e.message}"
    end

    def dump(value, **opts)
      type.dump(value, **opts)
    end

    def validate_type(value, context)
      # delegate check to type subclass if it exists
      return [] if value.nil? || type.valid_type?(value)

      msg = "Attribute #{Attributor.humanize_context(context)} received value: "
      msg += "#{Attributor.errorize_value(value)} is of the wrong type "
      msg += "(got: #{value.class.name}, expected: #{type.name})"
      [msg]
    end

    TOP_LEVEL_OPTIONS = [:description, :values, :default, :example, :required, :null, :custom_data].freeze
    INTERNAL_OPTIONS = [:dsl_compiler, :dsl_compiler_options].freeze # Options we don't want to expose when describing attributes
    def describe(shallow=true, example: nil)
      description = { }
      # Clone the common options
      TOP_LEVEL_OPTIONS.each do |option_name|
        description[option_name] = self.describe_option(option_name) if self.options.has_key? option_name
      end

      # Make sure this option definition is not mistaken for the real generated example
      if (ex_def = description.delete(:example))
        description[:example_definition] = ex_def
      end

      special_options = options.keys - TOP_LEVEL_OPTIONS - INTERNAL_OPTIONS
      description[:options] = {} unless special_options.empty?
      special_options.each do |opt_name|
        description[:options][opt_name] = self.describe_option(opt_name)
      end
      # Change the reference option to the actual class name.
      if (reference = options[:reference])
        description[:options][:reference] = reference.name
      end

      description[:type] = type.describe(shallow, example: example)
      # Move over any example from the type, into the attribute itself
      if (ex = description[:type].delete(:example))
        description[:example] = dump(ex)
      end

      description
    end

    def example_from_options(parent, context)
      val = options[:example]
      generated = case val
                  when ::Regexp
                    val.gen
                  when ::Proc
                    if val.arity == 2
                      val.call(parent, context)
                    elsif val.arity == 1
                      val.call(parent)
                    else
                      val.call
                    end
                  when nil
                    nil
                  else
                    val
                  end
      load(generated, context)
    end

    def describe_option( option_name )
      self.type.describe_option( option_name, self.options[option_name] )
    end

    # FiXME: pass and utilize the "shallow" parameter
    #required
    #options
    #type
    #example
    # UTILIZE THIS SITE! http://jsonschema.net/#/
    def as_json_schema(shallow: true, example: nil)
      description = self.type.as_json_schema(shallow: shallow, example: example, attribute_options: self.options )

      description[:description] = self.options[:description] if self.options[:description]
      description[:enum] = self.options[:values] if self.options[:values]
      if the_default = self.options[:default]
        the_object = the_default.is_a?(Proc) ? the_default.call : the_default
        description[:default] = the_object.is_a?(Attributor::Dumpable) ? the_object.dump : the_object
      end
      #TODO      description[:title] = "TODO: do we want to use a title??..."

      # Change the reference option to the actual class name.
      if ( reference = self.options[:reference] )
        description[:'x-reference'] = reference.name
      end

      # TODO: not sure if that's correct (we used to get it from the described hash...
      description[:example] = self.dump(example) if example

      # add custom options as x-optionname
      self.class.custom_options.each do |name, _|
        description["x-#{name}".to_sym] = self.options[name] if self.options.key?(name)
      end

      description
    end

    def example(context=nil, parent: nil, values:{})
      raise ArgumentError, "attribute example cannot take a context of type String" if (context.is_a? ::String )
      if context
        ctx = Attributor.humanize_context(context)
        seed, = Digest::SHA1.digest(ctx).unpack('QQ')
        Random.srand(seed)
      else
        context = Attributor::DEFAULT_ROOT_CONTEXT
      end

      if options.key? :example
        loaded = example_from_options(parent, context)
        # Only validate the type, if the proc-generated example is "complex" (has attributes)
        errors = loaded.class.respond_to?(:attributes) ? validate_type(loaded, context) : validate(loaded, context)
        raise AttributorException, "Error generating example for #{Attributor.humanize_context(context)}. Errors: #{errors.inspect}" if errors.any?
        return loaded
      end

      return options[:values].pick if options.key? :values

      if type.respond_to?(:attributes)
        type.example(context, **values)
      else
        type.example(context, options: options)
      end
    end

    def attributes
      type.attributes if @type_has_attributes ||= type.respond_to?(:attributes)
    end

    # Default value for a non-specified null: option 
    def self.default_for_null
      false
    end

    # It is only nullable if there is an explicit null: true (or if it's not passed/set, and the default is true)
    def self.nullable_attribute?(options)
      !options.key?(:null) ? default_for_null : options[:null]
    end

    # Validates stuff and checks dependencies
    def validate(object, context = Attributor::DEFAULT_ROOT_CONTEXT)
      raise "INVALID CONTEXT!! #{context}" unless context
      # Validate any requirements, absolute or conditional, and return.

      errors = []
      if object.nil? && !self.class.nullable_attribute?(options)
        errors << "Attribute #{Attributor.humanize_context(context)} is not nullable"
      else
        errors.push *validate_type(object, context)

        # If the value is null we skip value validation:
        # a) If null wasn't allowed, it would have failed above.
        # b) If null was allowed, we always allow that as a valid value
        if !object.nil? && options[:values] && !options[:values].include?(object)
          errors << "Attribute #{Attributor.humanize_context(context)}: #{Attributor.errorize_value(object)} is not within the allowed values=#{options[:values].inspect} "
        end
      end

      return errors if errors.any?
      
      object.nil? ? errors : errors + type.validate(object, context, self)
    end

    def check_options!
      options.each do |option_name, option_value|
        next unless check_option!(option_name, option_value) == :unknown
        if type.check_option!(option_name, option_value) == :unknown
          raise AttributorException, "unsupported option: #{option_name} with value: #{option_value.inspect} for attribute: #{inspect}"
        end
      end

      true
    end

    # TODO: override in type subclass
    def check_option!(name, definition)
      return check_custom_option(name, definition) if self.class.custom_options.include? name

      case name
      when :values
        raise AttributorException, "Allowed set of values requires an array. Got (#{definition})" unless definition.is_a? ::Array
      when :default
        raise AttributorException, "Default value doesn't have the correct attribute type. Got (#{definition.inspect})" unless type.valid_type?(definition) || definition.is_a?(Proc)
        options[:default] = load(definition) unless definition.is_a?(Proc)
      when :description
        raise AttributorException, "Description value must be a string. Got (#{definition})" unless definition.is_a? ::String
      when :required
        raise AttributorException, 'Required must be a boolean' unless definition == true || definition == false
        raise AttributorException, 'Required cannot be enabled in combination with :default' if definition == true && options.key?(:default)
      when :null
        raise AttributorException, 'Null must be a boolean' unless definition == true || definition == false        
      when :example
        unless definition.is_a?(::Regexp) || definition.is_a?(::String) || definition.is_a?(::Array) || definition.is_a?(::Proc) || definition.nil? || type.valid_type?(definition)
          raise AttributorException, "Invalid example type (got: #{definition.class.name}). It must always match the type of the attribute (except if passing Regex that is allowed for some types)"
        end
      when :custom_data
        raise AttributorException, "custom_data must be a Hash. Got (#{definition})" unless definition.is_a?(::Hash)
      else
        return :unknown # unknown option
      end

      :ok # passes
    end

    def check_custom_option(name, definition) 
      attribute = self.class.custom_options.fetch(name) 

      errors = attribute.validate(definition)
      raise AttributorException, "Custom option #{name.inspect} is invalid: #{errors.inspect}" if errors.any?

      :ok
    end
  end
end
