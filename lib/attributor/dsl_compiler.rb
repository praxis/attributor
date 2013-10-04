#Container of options and structure definition
module Attributor

  # RULES FOR ATTRIBUTES
  #   The type of an attribute is:
  #     the specified type
  #     inferred from a reference type.
  #       it should always end up being an anonymous type, otherwise the Model class will explode
  #     Struct if a block is given

  #   The reference option for an attribute is passed if a block is given

  class DSLCompiler

    attr_accessor :attributes, :options

    def initialize(options={})
      @options = options
      @attributes={}
    end


    def parse(&block)
      self.instance_eval(&block) if block
      return self
    end


    def parse_arguments(type_or_options, opts)
      type = nil

      if type_or_options.kind_of? ::Class
        type = type_or_options
      elsif type_or_options.kind_of? ::Hash
        opts = type_or_options
      end

      opts ||= {}
      return type, opts
    end


    def attribute(name, type_or_options=nil, opts={}, &block)
      raise AttributorException.new("Attribute #{name} already defined") if attributes.has_key? name

      type, opts = self.parse_arguments(type_or_options, opts)

      if (reference = self.options[:reference])
        inherited_attribute = reference.definition.attributes[name]
      else
        inherited_attribute = nil
      end

      if type.nil?
        if inherited_attribute
          type = inherited_attribute.type
          # Only inherit opts if no explicit type was given.
          opts = inherited_attribute.options.merge(opts)
        elsif block_given?
          type = Attributor::Struct
        else
          raise AttributorException, "type for attribute with name: #{name} could not be determined"
        end
      end

      if block_given? && inherited_attribute
        opts[:reference] = inherited_attribute.type
      end

      return attributes[name] = Attributor::Attribute.new(type, opts, &block)
    end


  end
end
