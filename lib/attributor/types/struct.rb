
module Attributor
  class Struct
    include Attributor::Model

    # Construct a new subclass, using attribute_definition to define attributes.
    def self.construct(attribute_definition, options={})
      raise AttributorException, 'can not construct from already-constructed Struct' unless self == Attributor::Struct
      # TODO: massage the options here to pull out only the relevant ones
      Class.new(self) do
        attributes options, &attribute_definition
        
      end
    end

  end
end
