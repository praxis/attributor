require 'date'

module Attributor
  class Date < Temporal
    def self.native_type
      ::Date
    end

    def self.example(context = nil, **_options)
      load(Randgen.date, context)
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return value if value.is_a?(native_type)
      return nil if value.nil?

      return value.to_date if value.respond_to?(:to_date)

      case value
      when ::String
        begin
          return ::Date.parse(value)
        rescue ArgumentError
          raise Attributor::DeserializationError, context: context, from: value.class, encoding: 'Date', value: value
        end
      else
        raise CoercionError, context: context, from: value.class, to: self, value: value
      end
    end
  end
end
