# TODO: profile keys for attributes, test as frozen strings

module Attributor
  class FakeParent < ::BasicObject
    def method_missing(name, *_args)
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

    # @options: metadata about the attribute
    # @block: code definition for struct attributes (nil for predefined types or leaf/simple types)
    def initialize(type, options = {}, &block)
      @type = Attributor.resolve_type(type, options, block)

      @options = options
      @options = @type.options.merge(@options) if @type.respond_to?(:options)

      check_options!
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
      unless type.valid_type?(value)
        msg = "Attribute #{Attributor.humanize_context(context)} received value: "
        msg += "#{Attributor.errorize_value(value)} is of the wrong type "
        msg += "(got: #{value.class.name}, expected: #{type.name})"
        return [msg]
      end
      []
    end

    TOP_LEVEL_OPTIONS = [:description, :values, :default, :example, :required, :required_if, :custom_data].freeze
    INTERNAL_OPTIONS = [:dsl_compiler, :dsl_compiler_options].freeze # Options we don't want to expose when describing attributes

    def describe(shallow = true, example: nil)
      description = {}
      # Clone the common options
      TOP_LEVEL_OPTIONS.each do |option_name|
        description[option_name] = options[option_name] if options.key? option_name
      end

      # Make sure this option definition is not mistaken for the real generated example
      if (ex_def = description.delete(:example))
        description[:example_definition] = ex_def
      end

      special_options = options.keys - TOP_LEVEL_OPTIONS - INTERNAL_OPTIONS
      description[:options] = {} unless special_options.empty?
      special_options.each do |opt_name|
        description[:options][opt_name] = options[opt_name]
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

    def example(context = nil, parent: nil, values:{})
      raise ArgumentError, 'attribute example cannot take a context of type String' if context.is_a? ::String
      if context
        ctx = Attributor.humanize_context(context)
        seed, = Digest::SHA1.digest(ctx).unpack('QQ')
        Random.srand(seed)
      else
        context = Attributor::DEFAULT_ROOT_CONTEXT
      end

      if options.key? :example
        loaded = example_from_options(parent, context)
        errors = validate(loaded, context)
        raise AttributorException, "Error generating example for #{Attributor.humanize_context(context)}. Errors: #{errors.inspect}" if errors.any?
        return loaded
      end

      return options[:values].pick if options.key? :values

      if type.respond_to?(:attributes)
        type.example(context, values)
      else
        type.example(context, options: options)
      end
    end

    def attributes
      type.attributes if @type_has_attributes ||= type.respond_to?(:attributes)
    end

    # Validates stuff and checks dependencies
    def validate(object, context = Attributor::DEFAULT_ROOT_CONTEXT)
      raise "INVALID CONTEXT!! #{context}" unless context
      # Validate any requirements, absolute or conditional, and return.

      if object.nil? # == Attributor::UNSET
        # With no value, we can only validate whether that is acceptable or not and return.
        # Beyond that, no further validation should be done.
        return validate_missing_value(context)
      end

      # TODO: support validation for other types of conditional dependencies based on values of other attributes

      errors = validate_type(object, context)

      # End validation if we don't even have the proper type to begin with
      return errors if errors.any?

      if options[:values] && !options[:values].include?(object)
        errors << "Attribute #{Attributor.humanize_context(context)}: #{Attributor.errorize_value(object)} is not within the allowed values=#{options[:values].inspect} "
      end

      errors + type.validate(object, context, self)
    end

    def validate_missing_value(context)
      raise "INVALID CONTEXT!!! (got: #{context.inspect})" unless context.is_a? Enumerable

      # Missing attribute was required if :required option was set
      return ["Attribute #{Attributor.humanize_context(context)} is required"] if options[:required]

      # Missing attribute was not required if :required_if (and :required)
      # option was NOT set
      requirement = options[:required_if]
      return [] unless requirement

      case requirement
      when ::String
        key_path = requirement
        predicate = nil
      when ::Hash
        # TODO: support multiple dependencies?
        key_path = requirement.keys.first
        predicate = requirement.values.first
      else
        # should never get here if the option validation worked...
        raise AttributorException, "unknown type of dependency: #{requirement.inspect} for #{Attributor.humanize_context(context)}"
      end

      # chop off the last part
      requirement_context = context[0..-2]
      requirement_context_string = requirement_context.join(Attributor::SEPARATOR)

      # FIXME: we're having to reconstruct a string context just to use the resolver...smell.
      if AttributeResolver.current.check(requirement_context_string, key_path, predicate)
        message = "Attribute #{Attributor.humanize_context(context)} is required when #{key_path} "

        # give a hint about what the full path for a relative key_path would be
        unless key_path[0..0] == Attributor::AttributeResolver::ROOT_PREFIX
          message << "(for #{Attributor.humanize_context(requirement_context)}) "
        end

        message << if predicate
                     "matches #{predicate.inspect}."
                   else
                     'is present.'
                   end

        [message]
      else
        []
      end
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
      when :required_if
        raise AttributorException, 'Required_if must be a String, a Hash definition or a Proc' unless definition.is_a?(::String) || definition.is_a?(::Hash) || definition.is_a?(::Proc)
        raise AttributorException, 'Required_if cannot be specified together with :required' if options[:required]
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
  end
end
