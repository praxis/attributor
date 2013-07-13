

  module Attributor

    class CSV < Array
      DEFAULT_EMPTY_CSV="__none__".freeze
      
      attr_reader :empty_csv_string
      def initialize(name, options, &block)
        @empty_csv_string = options[:empty_csv_string] || DEFAULT_EMPTY_CSV
        super( name, options , &block )
      end
      
      def validate_options( options_hash )       
        options_hash.each_pair do|opt,definition|
          case opt
          when :empty_csv_string
           raise ":empty_csv_string option must be a String (got: #{definition.inspect} )" unless definition.is_a? ::String
           options_hash.delete(:empty_csv_string)
          end
        end
        # Process the rest of options for the array
        super(options_hash)
      end
      
      # Attribute types that are more complex, might want to get the incoming value and decode it into the proper object before processing
      def decode( value, context )
        if value.is_a?(::String)
          sanitized = (value == empty_csv_string) ? [] : value.split(",")
        else
          sanitized = value
        end
        super(sanitized,context)
      end
      
    end

  end
