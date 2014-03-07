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
      
      # Decode JSON string that encapsulates an array
      #
      # @param value [String] JSON string
      # @return [Array] a normal Ruby Array
      #
      def decode_json(value)
      
        raise Attributor::DeserializationError, from: value.class, encoding: "JSON" , value: value unless value.kind_of? ::String
      
        # attempt to parse as JSON
        parsed_value = JSON.parse(value)

        if parsed_value.is_a? self.native_type
          value = parsed_value
        else
          raise Attributor::CoercionError, from: parsed_value.class, to: self.name, value: parsed_value
        end
        return value
      
      rescue JSON::JSONError => e
         raise Attributor::DeserializationError, from: value.class, encoding: "JSON" , value: value
      end
      
    end
    
  end
end