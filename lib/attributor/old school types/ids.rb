

  module Attributor

    class Ids < CSV
      DEFAULT_ELEMENT_TYPE = String
      EMPTY_ID_STRING = "__multiple_ids__".freeze
      # There are 2 main differences with a pure CSV:
      # 1- is that we need to handle the case of having a special empty keyword...      
      # 2- is that if the definition doesn't specify 'element_type', we'll default it to String
      def initialize(name, options, &block)
        new_opts = {:empty_csv_string => EMPTY_ID_STRING}
        new_opts[:element_type] = options[:element_type] || DEFAULT_ELEMENT_TYPE
        super( name, options.merge(new_opts), &block );        
      end
    end

  end
