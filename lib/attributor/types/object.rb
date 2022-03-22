# Represents any Object

require_relative '../exceptions'

module Attributor
  class Object
    include Type

    def self.native_type
      ::BasicObject
    end

    def self.example(_context = nil, options: {})
      'An Object'
    end

    # Not really used (we override as_json_schema to represent this as an Any Type),
    # but if it _were_ used, this would be accurate.
    def self.json_schema_type
      :object
    end

    # Represents Object as an OpenAPI Any Type.
    #
    # @see https://swagger.io/docs/specification/data-models/data-types/#any
    def self.as_json_schema(**kwargs)
      schema = super(**kwargs)
      schema.delete(:type)
      schema
    end
  end
end
