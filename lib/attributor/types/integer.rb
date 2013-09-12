

  module Attributor

    class Integer
      include Type

      def self.native_type
        return ::Integer
      end

      def self.example(options={})
        min = options[:min] || 0
        max = options[:max] || 1000

        rand(max-min) + min
      end
      
      def self.load(value)
        super
      end

      #def self.validate(value, context, attribute)
      #  super
      #end
      

      # def self.decode( value, context , definition)
      #   errors = []
      #   # We assume that if the value is already in the right type, we've decoded it already
      #   if( value.is_a?(self.native_type) )
      #     decoded = value
      #   # Else, we'll decode it from String...and pass it to the parent array type (so it can deal with element_type and other options)
      #   elsif value.is_a?(::String)
      #     begin
      #       decoded = Integer(value)
      #     rescue Exception => e
      #       #TODO: error handling #Returning the String so the type fails for now...
      #       errors << "Could not decode an integer from this String. (Got: #{value})"
      #     end
      #   else
      #     errors << "Do not know how to load an integer from (#{value})"
      #   end
      #   [ decoded, errors ]
      # end

  

    end    
  end

