# frozen_string_literal: true

require 'date'
require 'time'

module Attributor
  class Time < Temporal
    include Type

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
        ::Time.at(value)
      when ::String
        begin
          return ::Time.parse(value)
        rescue ArgumentError
          raise Attributor::DeserializationError, context: context, from: value.class, encoding: 'Time', value: value
        end
      else
        raise CoercionError, context: context, from: value.class, to: self, value: value
      end
    end
  end
end
