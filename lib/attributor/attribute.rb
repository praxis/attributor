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
      @saved_block = block
      # @inherit_from = @options.delete(:inherit_from) # AttributeType object to inherit options/subdefinitions from

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
      unless value.is_a? self.native_type
        return ["Attribute #{context} received value: #{value.inspect} is of the wrong type (got: #{value.class.name} expected: #{self.native_type.name})"]
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


    def native_type
      self.type.native_type
    end


    def example(context=nil)
      if context
        seed, _ = Digest::SHA1.digest(context).unpack("QQ")
        Random.srand(seed) 
      end

      val = self.options[:example]

      case val
      when ::String
        # FIXME: spec this properly to use self.native_type
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
        raise "unknown example type, got: #{val}"
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
        #@compiled_definition = type.definition( @options, @saved_block )
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
        if self.options[:required]
          return ["Attribute #{context} is required"]
        else
          return self.validate_dependency(context)
        end
      end

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


    def validate_dependency(context)
      return [] unless self.options.has_key? :required_if

      requirement = self.options[:required_if]

      case requirement
      when ::String
        key_path = requirement
        condition = nil
      when ::Hash
        # TODO: support multiple dependencies?
        key_path = requirement.keys.first
        condition = requirement.values.first
      else
        raise "unknown type of dependency: #{requirement.inspect}" # should never get here if the option validation worked...
      end


      # TODO: need to pass object in here (if we want to have conditions that use the attribute's value)
      if AttributeResolver.current.check(context, key_path, condition)
        return []
      else
        return ["Attribute #{context.inspect} fails to satisfy dependency #{requirement.inspect}"]
      end
    end


    def check_options!
      self.options.each do |option_name, option_value|
        if self.check_option!(option_name, option_value) == :unknown
          if self.type.check_option!(option_name, option_value) == :unknown
            raise "unsupported option: #{option_name} with value: #{option_value.inspect} for attribute: #{self.inspect}"
          end
        end
      end

      true
    end


    def check_option!(name, definition)
      case name
      when :values
        raise "Allowed set of values requires an array. Got (#{definition})" unless definition.is_a? ::Array
      when :default
        raise "Default value doesn't have the correct type. Requires (#{self.native_type.name}). Got (#{definition})" unless definition.is_a? self.native_type
      when :description
        raise "Description value must be a string. Got (#{definition})" unless definition.is_a? ::String
      when :required
        raise "Required must be a boolean" unless !!definition == definition # Boolean check
        raise "Required cannot be enabled in combination with :default" if definition == true && options.has_key?(:default)
      when :required_if
        raise "Required_if must be a String, a Hash definition or a Proc" unless definition.is_a?(::String) || definition.is_a?(::Hash) || definition.is_a?(::Proc)
        raise "Required_if cannot be specified together with :required" if self.options[:required]
      when :example
        unless definition.is_a?(self.native_type) || definition.is_a?(::Regexp) || definition.is_a?(::String) || definition.is_a?(::Array)
          raise "Invalid example type (got: #{definition.class.name}) for type (#{self.native_type.inspect}). It must always match the type of the attribute (except if passing Regex that is allowed for some types)"
        end
      else
        return :unknown # unknown option
      end

      :ok # passes
    end

  end
end
