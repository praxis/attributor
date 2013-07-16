# Hack to make a common bool class
module ::Boolean; end
class TrueClass; include ::Boolean; end
class FalseClass; include ::Boolean; end

  module Attributor

    class Boolean < Attribute

      def supported_options_for_type
        [] 
      end
      
      def self.native_type
        return ::Boolean
      end
            
      def decode( value, context )
        errors = []
        # We assume that if the value is already in the right type, we've decoded it already
        if( value.is_a?(self.native_type) )
          decoded = value
        # Else, we'll decode it from String...and pass it to the parent array type (so it can deal with element_type and other options)
        elsif value.is_a?(::String)
          decoded = case value
            when "true","1"
              true
            when "false","0"
              false
            else
              errors << "Could not decode a boolean from this String. (Got: #{value})"
              nil
            end
        elsif value.is_a?(::Integer)
          decoded = case value
          when 1
            true
          when 0
            false
          else
            errors << "Could not decode a boolean from this Integer. (Got: #{value})"
            nil            
          end
        else
          errors << "Do not know how to load an integer from (#{value})"
        end
        [ decoded, errors ]
      end
    end

  end

