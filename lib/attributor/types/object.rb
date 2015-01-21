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
        
    def self.json_schema_type
      :object #FIXME: not sure this is the most appropriate, since an Attributor::Object can be anything
    end

  end
end
