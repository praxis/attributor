module Attributor
  class Ids < CSV
    def self.for(type)
      identity_name = type.options.fetch(:identity) do
        raise AttributorException, "no identity found for #{type.name}"
      end

      identity_attribute = type.attributes.fetch(identity_name) do
        raise AttributorException, "#{type.name} does not have attribute with name '#{identity_name}'"
      end

      ::Class.new(self) do
        @member_attribute = identity_attribute
        @member_type = identity_attribute.type
      end
    end

    def self.of(_type)
      raise 'Invalid definition of Ids type. Defining Ids.of(type) is not allowed, you probably meant to do Ids.for(type) instead'
    end
  end
end
