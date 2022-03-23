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

    # Represents Object as an OpenAPI Any Type.
    # Which means there is no type key for an Object (i.e., 'any'), so we'll report it as nil
    #
    # @see https://swagger.io/docs/specification/data-models/data-types/#any
    def self.json_schema_type
      nil
    end
  end
end
