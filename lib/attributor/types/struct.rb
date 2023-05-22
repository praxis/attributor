
module Attributor
  class Struct < Attributor::Model
    def self.constructable?
      true
    end

    # Construct a new subclass, using attribute_definition to define attributes.
    def self.construct(attribute_definition, options = {})
      # if we're in a subclass of Struct, but no attribute_definition is provided, we're
      # not REALLY trying to define a new struct. more than likely Collection is calling
      # construct on us.
      unless self == Attributor::Struct || attribute_definition.nil?
        location_file, location_line = attribute_definition.source_location
        message = "You cannot change an already defined Struct type:\n"
        message += "It seems you are trying to define attributes, using a block, on top of an existing concrete Struct type that already has been fully defined.\n"
        message += "The place where you are trying to define the type is here:\n#{location_file} line #{location_line}\n#{attribute_definition.source}\n"
        message += "If what you meant was to define a brand new Struct or Struct[], please make sure you pass the type in the attribute definition,\n"
        message += "rather than leaving it blank.\n"
        message += "Otherwise, what might be happening is that you have left out the explicit type, and the framework has inferred it from the"
        message += "corresponding :reference type attribute (and hence running into the conflict of trying to redefine an existing type)."
        raise AttributorException, message
      end

      # TODO: massage the options here to pull out only the relevant ones

      # simply return Struct if we don't specify any sub-attributes....
      return self if attribute_definition.nil?

      if options[:reference]
        options.merge!(options[:reference].options) do |_key, oldval, _newval|
          oldval
        end
      end

      ::Class.new(self) do
        attributes **options, &attribute_definition
      end
    end

    def self.definition
      # Could probably do this better, but its use should be memoized in the enclosing Attribute
      raise AttributorException, 'Can not use a pure Struct without defining sub-attributes' if self == Attributor::Struct

      super
    end

    # Two structs are equal if their attributes are equal
    def ==(other)
      return false if other.nil? || !other.respond_to?(:attributes)
      attributes == other.attributes
    end
  end
end
