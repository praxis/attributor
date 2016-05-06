module Attributor
  module Container
    # Module for types that can contain subtypes. Collection.of(?) or Hash.of(?)
    def self.included(klass)
      klass.module_eval do
        include Attributor::Type
      end
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def decode_string(_value, context = Attributor::DEFAULT_ROOT_CONTEXT)
        raise "#{name}.decode_string is not implemented. (when decoding #{Attributor.humanize_context(context)})"
      end

      # Decode JSON string that encapsulates an array
      #
      # @param value [String] JSON string
      # @return [Array] a normal Ruby Array
      #
      def decode_json(value, context = Attributor::DEFAULT_ROOT_CONTEXT)
        raise Attributor::DeserializationError, context: context, from: value.class, encoding: 'JSON', value: value unless value.is_a? ::String

        # attempt to parse as JSON
        parsed_value = JSON.parse(value)
        unless valid_type?(parsed_value)
          raise Attributor::CoercionError, context: context, from: parsed_value.class, to: name, value: parsed_value
        end

        parsed_value
      rescue JSON::JSONError
        raise Attributor::DeserializationError, context: context, from: value.class, encoding: 'JSON', value: value
      end
    end
  end
end
