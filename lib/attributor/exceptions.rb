module Attributor
  class AttributorException < ::StandardError
  end

  class LoadError < AttributorException
  end

  class IncompatibleTypeError < LoadError
    def initialize(type:, value_type:, context:)
      super "Type #{type} cannot load values of type #{value_type} while loading #{Attributor.humanize_context(context)}."
    end
  end

  class CoercionError < LoadError
    def initialize(context:, from:, to:, value: nil)
      msg = "Error coercing from #{from} to #{to} while loading #{Attributor.humanize_context(context)}."
      msg += " Received value #{Attributor.errorize_value(value)}" if value
      super msg
    end
  end

  class DeserializationError < LoadError
    def initialize(context:, from:, encoding:, value: nil)
      msg = "Error deserializing a #{from} using #{encoding} while loading #{Attributor.humanize_context(context)}."
      msg += " Received value #{Attributor.errorize_value(value)}" if value
      super msg
    end
  end

  class DumpError < AttributorException
    def initialize(context:, name:, type:, original_exception:)
      msg = "Error while dumping attribute #{name} of type #{type} for context #{Attributor.humanize_context(context)}."
      msg << " Reason: #{original_exception}"
      super msg
    end
  end
end
