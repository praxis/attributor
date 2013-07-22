

  module Attributor

    class Integer < Attribute

      def supported_options_for_type
        [:min,:max]
      end
      
      def self.native_type
        return ::Integer
      end
      
      def validate(value,context)
        errors = []
        @options.each_pair do |option, definition|
          case option
          when :max 
            errors << "#{context} value is larger than the allowed max (#{definition})" unless value <= definition 
          when :min 
            errors << "#{context} value is smaller than the allowed min (#{definition})" unless value >= definition 
          end
        end
        errors
      end

      def decode( value, context )
        errors = []
        # We assume that if the value is already in the right type, we've decoded it already
        if( value.is_a?(self.native_type) )
          decoded = value
        # Else, we'll decode it from String...and pass it to the parent array type (so it can deal with element_type and other options)
        elsif value.is_a?(::String)
          begin
            decoded = Integer(value)
          rescue Exception => e
            #TODO: error handling #Returning the String so the type fails for now...
            errors << "Could not decode an integer from this String. (Got: #{value})"
          end
        else
          errors << "Do not know how to load an integer from (#{value})"
        end
        [ decoded, errors ]
      end

      def example
        if value = options[:example]
          if value.kind_of? Regexp
            return value.gen.to_i
          else
            return value
          end
        end
        
        return super if options.has_key?(:default) || options.has_key?(:value)
        
        min = options[:min] || 0
        max = options[:max] || 1000
        rand(max-min) + min
      end   

    end    
  end

