# Represents any Object

require_relative '../exceptions'

module Attributor

  class Object
    include Type

    def self.native_type
      return ::Object
    end

    def self.example(options={},context=nil)
      'An Object'
    end

  end
end
