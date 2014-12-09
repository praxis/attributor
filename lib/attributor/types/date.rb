require 'date'

module Attributor

    class Date
      include Type

      def self.native_type
        return ::Date
      end

      def self.example(context=nil, options: {})
        return self.load(/[:date:]/.gen, context)
      end

      def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
        # We assume that if the value is already in the right type, we've decoded it already
        return value if value.is_a?(self.native_type)
        if value.respond_to?(:to_date)
          return value.to_date
        end

        return nil unless value.is_a?(::String)
        begin
          return ::Date.parse(value)
        rescue ArgumentError => e
          raise Attributor::DeserializationError, context: context, from: value.class, encoding: "Date" , value: value            
        end
      end

    end

  end

