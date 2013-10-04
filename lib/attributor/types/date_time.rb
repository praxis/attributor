# Represents a plain old boolean type. TBD: can be nil?
#
require_relative '../exceptions'
require 'date'

module Attributor

    class DateTime
      include Type

      ATTRIBUTOR_EPOCH = ::DateTime.new(2013, 9, 30, 8, 0, 0)

      def self.native_type
        return ::DateTime
      end

      def self.example
        return ATTRIBUTOR_EPOCH - rand(1000)
      end

      def self.load(value)
        # We assume that if the value is already in the right type, we've decoded it already
        return value if value.is_a?(self.native_type)
        return nil unless value.is_a?(::String)
        # TODO: we should be able to convert not only from String but Time...etc
        # Else, we'll decode it from String.
        begin
          return ::DateTime.parse(value)
        rescue ArgumentError => e
          raise AttributorException.new("#{e.message}: #{value.inspect}")
        end
      end

    end

  end

