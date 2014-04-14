# TODO: profile keys for attributes, test as frozen strings

module Attributor

  # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
  # TODO: should this be a mixin since it is an abstract class?
  class Attribute

    attr_reader :type, :options

    # @options: metadata about the attribute
    # @block: code definition for struct attributes (nil for predefined types or leaf/simple types)
    def initialize(type, options={}, &block)
      @type = Attributor.resolve_type(type, options, block)

      @options = options
      if @type.respond_to?(:options)
        @options = @type.options.merge(@options)
      end

      check_options!
    end

    def parse(value, context=Attributor::DEFAULT_ROOT_CONTEXT)
      object = self.load(value,context)

      errors = self.validate(object,context)
      [ object, errors ]
    end


    def load(value,context=Attributor::DEFAULT_ROOT_CONTEXT)
      value = type.load(value,context ) unless value.nil?

      # just in case type.load(value) returned nil, even though value is not nil.
      if value.nil?
        value = self.options[:default] if self.options[:default]
      end

      value
    rescue AttributorException, NameError
      raise
    rescue => e
      raise Attributor::LoadError, "Error loading attribute #{Attributor.humanize_context(context)} of type #{type.name} from value #{value.inspect}\n#{e.message}"
    end

    def dump(value, **opts)
      type.dump(value, opts)
    end


    def validate_type(value, context)
      # delegate check to type subclass if it exists
      unless self.type.valid_type?(value)
        return ["Attribute #{Attributor.humanize_context(context)} received value: #{value.inspect} is of the wrong type (got: #{value.class.name})"]
      end
      []
    end


    def describe(shallow=true)
      description = self.options.clone
      # Make sure this option definition is not mistaken for the real generated example
      if ( ex_def = description.delete(:example) )
        description[:example_definition] = ex_def
      end

      if (reference = description.delete :reference)
        description[:reference] = reference.name
      end

      description[:type] = self.type.describe(shallow)
      description
    end


    def example(context=nil, parent: nil, values:{})
      raise ArgumentError, "attribute example cannot take a context of type String" if (context.is_a? ::String )
      if context
        ctx = Attributor.humanize_context(context)            
        seed, _ = Digest::SHA1.digest(ctx).unpack("QQ")
        Random.srand(seed)
      end

      if self.options.has_key? :example
        val = self.options[:example] 
        case val
        when ::String
          # FIXME: spec this properly to use self.type.native_type
          val
        when ::Regexp
          self.load(val.gen,context)
        when ::Array
          # TODO: handle arrays of non native types, i.e. arrays of regexps.... ?
          val.pick
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
          raise AttributorException, "unknown example attribute type, got: #{val}"
        end
      else
        if (option_values = self.options[:values])
          option_values.pick
        else
          if type.respond_to?(:attributes)
            self.type.example(context, values)
          else
            self.type.example(context, options: self.options)
          end
        end
      end
    end


    def attributes
      @attributes ||= begin
        if type.respond_to?(:attributes)
          type.attributes
        else
          nil
        end
      end
    end


    # Validates stuff and checks dependencies
    def validate(object, context=Attributor::DEFAULT_ROOT_CONTEXT )
      raise "INVALID CONTEXT!! #{context}" unless context
      # Validate any requirements, absolute or conditional, and return.

      if object.nil? # == Attributor::UNSET
        # With no value, we can only validate whether that is acceptable or not and return.
        # Beyond that, no further validation should be done.
        return self.validate_missing_value(context)
      end

      # TODO: support validation for other types of conditional dependencies based on values of other attributes

      errors = self.validate_type(object,context)

      # End validation if we don't even have the proper type to begin with
      return errors if errors.any?

      if self.options[:values] && !self.options[:values].include?(object)
        errors << "Attribute #{Attributor.humanize_context(context)}: #{object.inspect} is not within the allowed values=#{self.options[:values].inspect} "
      end

      errors + self.type.validate(object,context,self)
    end


    def validate_missing_value(context)
      raise "INVALID CONTEXT!!! (got: #{context.inspect})" unless context.is_a? Enumerable
      
      # Missing attribute was required if :required option was set
      return ["Attribute #{Attributor.humanize_context(context)} is required"] if self.options[:required]

      # Missing attribute was not required if :required_if (and :required)
      # option was NOT set
      requirement = self.options[:required_if]
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
        raise AttributorException.new("unknown type of dependency: #{requirement.inspect} for #{Attributor.humanize_context(context)}")
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

        if predicate
          message << "matches #{predicate.inspect}."
        else
          message << "is present."
        end

        [message]
      else
        []
      end
    end


    def check_options!
      self.options.each do |option_name, option_value|
        if self.check_option!(option_name, option_value) == :unknown
          if self.type.check_option!(option_name, option_value) == :unknown
            raise AttributorException.new("unsupported option: #{option_name} with value: #{option_value.inspect} for attribute: #{self.inspect}")
          end
        end
      end

      true
    end


    # TODO: override in type subclass
    def check_option!(name, definition)
      case name
      when :values
        raise AttributorException.new("Allowed set of values requires an array. Got (#{definition})") unless definition.is_a? ::Array
      when :default
        raise AttributorException.new("Default value doesn't have the correct attribute type. Got (#{definition.inspect})") unless self.type.valid_type?(definition)
      when :description
        raise AttributorException.new("Description value must be a string. Got (#{definition})") unless definition.is_a? ::String
      when :required
        raise AttributorException.new("Required must be a boolean") unless !!definition == definition # Boolean check
        raise AttributorException.new("Required cannot be enabled in combination with :default") if definition == true && options.has_key?(:default)
      when :required_if
        raise AttributorException.new("Required_if must be a String, a Hash definition or a Proc") unless definition.is_a?(::String) || definition.is_a?(::Hash) || definition.is_a?(::Proc)
        raise AttributorException.new("Required_if cannot be specified together with :required") if self.options[:required]
      when :example
        unless definition.is_a?(::Regexp) || definition.is_a?(::String) || definition.is_a?(::Array) || definition.is_a?(::Proc) || definition.nil? || self.type.valid_type?(definition) 
          raise AttributorException.new("Invalid example type (got: #{definition.class.name}). It must always match the type of the attribute (except if passing Regex that is allowed for some types)")
        end
      else
        return :unknown # unknown option
      end

      :ok # passes
    end

  end
end
