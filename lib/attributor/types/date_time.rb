# Represents a plain old boolean type. TBD: can be nil?
#
require_relative '../exceptions'
require 'date'

module Attributor

    class DateTime
      include Type

      def self.native_type
        return ::DateTime
      end

      def self.example(context=nil, options: {})
        return self.load(/[:date:]/.gen)
      end

      def self.load(value)
        # We assume that if the value is already in the right type, we've decoded it already
        return value if value.is_a?(self.native_type)
        return value.to_datetime if value.is_a?(::Time)
        return nil unless value.is_a?(::String)
        # TODO: we should be able to convert not only from String but Time...etc
        # Else, we'll decode it from String.
        begin
          return ::DateTime.parse(value)
        rescue ArgumentError => e
          raise Attributor::DeserializationError, from: value.class, encoding: "DateTime" , value: value            
        end
      end

    end

  end

