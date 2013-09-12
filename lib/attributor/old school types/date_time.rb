

  module Attributor

    class DateTime < Attribute

      def self.native_type
        return ::DateTime
      end

      def decode( value, context )        
        # We assume that if the value is already in the right type, we've decoded it already
        return value if value.is_a?(self.native_type)
        return nil unless value.is_a?(::String)
        # TODO: we should be able to convert not only from String but Time...etc
        # Else, we'll decode it from String.
        return ::DateTime.parse(value)
      end

      #Nothing to validate for the moment
      def validate(value,context)
        []
      end
    end

  end

