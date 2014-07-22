# Represents any Object

require_relative '../exceptions'

module Attributor

  class Object
    include Type

    def self.native_type
      return ::BasicObject
    end

    def self.example(context=nil, options:{})
      'An Object'
    end

  end
end
