# Represents any Object

require_relative '../exceptions'

module Attributor
  class Object
    include Type

    def self.native_type
      ::BasicObject
    end

    def self.example(_context = nil, **_options)
      'An Object'
    end
  end
end
