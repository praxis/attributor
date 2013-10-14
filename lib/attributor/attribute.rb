# TODO: profile keys for attributes, test as frozen strings

module Attributor

  # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
  # TODO: should this be a mixin since it is an abstract class?
  class Attribute

   

    attr_reader :type

    # @options: metadata about the attribute
    # @block: code definition for struct attributes (nil for predefined types or leaf/simple types)
    def initialize(type, options={}, &block)
      @type = Attributor.resolve_type(type, options, block)
      @options = options

      check_options!
    end


    def parse(value)
      object = self.load(value)

      errors = self.validate(object)
      [ object, errors ]
    end


    # TODO:  might want to expose load directly too?..."
    def load(value)
      value = type.load(value) unless value.nil?

      # just in case type.load(value) returned nil, even though value is not nil.
      if value.nil?
        value = self.options[:default] if self.options[:default]
      end

      value
    end

    def validate_type(value, context)
      # delegate check to type subclass if it exists
      unless self.type.valid_type?(value)
        return ["Attribute #{context} received value: #{value.inspect} is of the wrong type (got: #{value.class.name} expected: #{self.type.native_type.name})"]
      end
      []
    end


    # TODO: split bits of this...
    def describe
      type_name = self.type.ancestors.find { |k| k.name }.name

      hash = {:type => type_name.split('::').last }.merge(options)

      if self.attributes
        sub_attributes = {}
        self.attributes.each do |sub_name, sub_attribute|
          sub_attributes[sub_name] = sub_attribute.describe
        end
        hash[:attributes] = sub_attributes
      end

      hash
    end

    def example(context=nil)
      if context
        seed, _ = Digest::SHA1.digest(context).unpack("QQ")
        Random.srand(seed)
      end

      val = self.options[:example]

      case val
      when ::String
        # FIXME: spec this properly to use self.type.native_type
        val
      when ::Regexp
        self.load(val.gen)
      when ::Array
        # TODO: handle arrays of non native types, i.e. arrays of regexps.... ?
        val.pick
      when nil
        if values = self.options[:values]
          values.pick
        else
          self.type.example(self.options, context)
        end
      else
        raise AttributorException.new("unknown example type, got: #{val}")
      end
    end


    def attributes
      if type < Model
        compiled_definition.attributes
      else
        nil
      end
    end


    def options
      if type < Model
        compiled_definition unless @compiled_definition
        @compiled_options
      else # Simple, no DSL anywhere type
        @options
      end
    end


    # Lazy compilation
    def compiled_definition
      unless @compiled_definition
        @compiled_definition = type.definition
        @compiled_options = @compiled_definition.options.merge(@options)
      end
      @compiled_definition
    end


    # Validates stuff and checks dependencies
    def validate(object, context=nil)
      errors=[]

      # Validate any requirements, absolute or conditional, and return.


      if object.nil? # == Attributor::UNSET
        # With no value, we can only validate whether that is acceptable or not and return. 
        # Beyond that, no further validation should be done.
        return self.validate_missing_value(context)
      end

      # TODO: support validation for other types of conditional dependencies based on values of other attributes

      errors += self.validate_type(object,context)

      if self.options[:values] && !self.options[:values].include?(object)
        errors << "Attribute #{context}: #{object.inspect} is not within the allowed values=#{self.options[:values].inspect} "
      end

      errors += self.type.validate(object,context,self)

      if self.attributes
        self.attributes.each do |sub_attribute_name, sub_attribute|
          sub_context = self.type.generate_subcontext(context,sub_attribute_name)
          errors += sub_attribute.validate(object.get(sub_attribute_name), sub_context)
        end
      end

      errors
    end


    def validate_missing_value(context)
      return ["Attribute #{context} is required"] if self.options[:required]
        
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
        raise AttributorException.new("unknown type of dependency: #{requirement.inspect}") # should never get here if the option validation worked...
      end

      *requirement_context, _ = context.split(Attributor::SEPARATOR)
      requirement_context = requirement_context.join(Attributor::SEPARATOR)
      # OPTIMIZE: probably should.

      if AttributeResolver.current.check(requirement_context, key_path, predicate)
        message = "Attribute #{context} is required when #{key_path} "

        # give a hint about what the full path for a relative key_path would be
        unless key_path[0] == Attributor::AttributeResolver::ROOT_PREFIX
         message << "(for #{requirement_context}) "
        end

        if predicate
          message << "matches #{predicate.inspect}."
        else
          message << "is present."
        end

        return [message]
      else
        return []
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
        raise AttributorException.new("Default value doesn't have the correct type. Got (#{definition})") unless self.type.valid_type?(definition)
      when :description
        raise AttributorException.new("Description value must be a string. Got (#{definition})") unless definition.is_a? ::String
      when :required
        raise AttributorException.new("Required must be a boolean") unless !!definition == definition # Boolean check
        raise AttributorException.new("Required cannot be enabled in combination with :default") if definition == true && options.has_key?(:default)
      when :required_if
        raise AttributorException.new("Required_if must be a String, a Hash definition or a Proc") unless definition.is_a?(::String) || definition.is_a?(::Hash) || definition.is_a?(::Proc)
        raise AttributorException.new("Required_if cannot be specified together with :required") if self.options[:required]
      when :example
        unless self.type.valid_type?(definition) || definition.is_a?(::Regexp) || definition.is_a?(::String) || definition.is_a?(::Array)
          raise AttributorException.new("Invalid example type (got: #{definition.class.name}). It must always match the type of the attribute (except if passing Regex that is allowed for some types)")
        end
      else
        return :unknown # unknown option
      end

      :ok # passes
    end

  end
end
