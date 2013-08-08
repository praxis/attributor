

  module Attributor

    class Integer
      include Base
      
      def self.supported_options_for_type
        [:min,:max]
      end
      
      def self.native_type
        return ::Integer
      end
      
      def self.validate(value,context,definition)
        errors = []
        definition.options.each_pair do |option, opt_definition|
          case option
          when :max 
            errors << "#{context} value is larger than the allowed max (#{opt_definition})" unless value <= opt_definition 
          when :min 
            errors << "#{context} value is smaller than the allowed min (#{opt_definition})" unless value >= opt_definition 
          end
        end
        errors
      end

      def self.decode( value, context , definition)
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

      def self.example
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

