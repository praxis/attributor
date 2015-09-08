
module Attributor
  class Struct < Attributor::Model

    def self.constructable?
      true
    end

    # Construct a new subclass, using attribute_definition to define attributes.
    def self.construct(attribute_definition, options={})
      # if we're in a subclass of Struct, but not attribute_definition is provided, we're
      # not REALLY trying to define a new struct. more than likely Collection is calling
      # construct on us.
      unless self == Attributor::Struct || attribute_definition.nil?
        raise AttributorException, 'can not construct from already-constructed Struct'
      end

      # TODO: massage the options here to pull out only the relevant ones

      # simply return Struct if we don't specify any sub-attributes....
      return self if attribute_definition.nil?

      if options[:reference]
        options.merge!(options[:reference].options) do |key, oldval, newval|
          oldval
        end
      end

      ::Class.new(self) do
        attributes options, &attribute_definition
      end

    end


    def self.definition
      # Could probably do this better, but its use should be memoized in the enclosing Attribute
      if self == Attributor::Struct
        raise AttributorException, "Can not use a pure Struct without defining sub-attributes"
      else
        super
      end
    end


    # Two structs are equal if their attributes are equal
    def ==(other_object)
      return false if other_object == nil || !other_object.respond_to?(:attributes)
      self.attributes == other_object.attributes
    end

  end
end
