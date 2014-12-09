require 'date'

module Attributor

  class Time
    include Type

    def self.native_type
      return ::Time
    end

    def self.example(context=nil, options: {})
      return self.load(/[:time:]/.gen, context)
    end

    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      # We assume that if the value is already in the right type, we've decoded it already
      return value if value.is_a?(self.native_type)
      if value.respond_to?(:to_time)
        return value.to_time
      end

      case value
      when ::Integer
        return ::Time.at(value)
      when ::String
        begin
          return ::Time.parse(value)
        rescue ArgumentError => e
          raise Attributor::DeserializationError, context: context, from: value.class, encoding: "Time" , value: value
        end
      end
    end

  end

end

