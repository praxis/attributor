module Attributor
  class AttributorException < ::StandardError
  end

  class LoadError < AttributorException
  end
  
  class IncompatibleTypeError < LoadError
    
    def initialize(type:, value_type:)
      super "Type #{type} cannot load values of type #{value_type}"
    end
  end

  class CoercionError < LoadError
    def initialize( from: , to:, value: nil)
      msg = "Error coercing from #{from} to #{to}."
      msg += " Received value #{value.inspect}" if value
      super msg
    end
  end
  
  class DeserializationError < LoadError
    def initialize( from:, encoding: , value: nil)
      msg = "Error deserializing a #{from} using #{encoding}."
      msg += " Received value #{value.inspect}" if value
      super msg
    end  
  end
  
end