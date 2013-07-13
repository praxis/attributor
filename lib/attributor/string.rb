

  module Attributor


    class String < Attribute

      def supported_options_for_type
        [:regexp]
      end
      
      def validate(value,context)
        errors = []  
        @options.each do |opt, definition|
          case opt
          when :regexp
            match = definition =~ value
            errors << "#{context} value does not match regexp" unless match 
          end
        end
        errors
      end

      def decode( value, context )
        errors = []
        if( value.is_a? ::String)
          decoded = value
        else
          errors << "Do not know how to load a string from #{value.class.name}"
        end
        {:errors => errors, :loaded_value => decoded }
      end

      def self.native_type
        return ::String
      end
      

    end

  end

