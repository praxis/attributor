require 'date'

module Attributor
  class Time
    include Temporal

    def self.native_type
      ::Time
    end

    def self.example(context = nil, options: {})
      load(Randgen.time, context)
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return value if value.is_a?(native_type)
      return nil if value.nil?

      return value.to_time if value.respond_to?(:to_time)

      self.parse(value, context)
    end

    def self.parse(value, context)
      case value
      when ::Integer
        return ::Time.at(value)
      when ::String
        begin
          return ::Time.parse(value)
        rescue ArgumentError
          raise Attributor::DeserializationError.new(context: context, from: value.class, encoding: 'Time', value: value)
        end
      else
        raise CoercionError, context: context, from: value.class, to: self, value: value
      end
    end

    def self.json_schema_string_format
      :time
    end
  end
end
