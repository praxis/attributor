

  module Attributor


    class Array < Attribute
      
      # Invoked at the end of the attribute initializatino
      # We will create and store a skeletor attribute based on the element_type class (defaulting to Hash)
      # If a block is passed, we will pass it along when we instantiate the attribute
      def parse_block(&block)

        # Nothing to finish up if there's no block or element type
        return if !block_given? && !@options[:element_type]
        array_element_type = @options[:element_type] || Attributor::Hash
        
        if block_given? && array_element_type != Attributor::Hash
            raise "Arrays can only be defined by a block when element_type is a Hash (or unset)"
        end
        raise "Error: element_type option for Array #{name} is not correctly set"  unless array_element_type < Attribute
        raise "Array element structure already defined" unless @sub_definition.nil?
        
        sub_options ={}     
        if @inherit_from
          raise "attribute #{name} cannot inherit from objects that do are not 'Attribute' type (got: #{@inherit_from.class.name})" unless @inherit_from.is_a? Attribute
          raise "attribute #{name} (of type Array) cannot inherit from #{@inherit_from.class.name} (this Attribute is not an Array)" unless @inherit_from.is_a? Array
          sub_options[:inherit_from] = @inherit_from.sub_definition
        end
        @sub_definition = array_element_type.new("_array_substructure_", sub_options, &block) #name for the element will never be used
      end


      def validate_options( options_hash )
        supported_opts = [:max_size]
        validated = common_options_validator_helper(supported_opts, options_hash )
        
        remaining = options_hash.reject{|k,_| validated.include? k }
        remaining.each_pair do|opt,definition|
          case opt
          when :element_type
#            raise "Type #{definition} not supported for element_type in Array [#{definition.ancestors}]" unless  definition < Attribute 
            begin
              the_class = Attributor.determine_class(definition)
              # Crude way to make sure that we always store an attributor class in the options (even if the incoming one was a native one)
              @options[:element_type] = the_class
            rescue Exception
              raise "Type #{definition} not supported for element_type in Array [#{definition.ancestors}]"
            end
          else
            raise "ERROR, unknown option/s (#{opt}) for #{native_type} attribute type"
          end
        end
      end


      def validate(value,context)
        errors = []
        @options.each_pair do |option, definition|
          case option
          when :max_size
            errors << "Array #{context} contains more elements than the allowed max_count (#{definition})" unless value.size <= definition
          when :element_type
            correct_type = value.all? {|element| element.is_a?(@options[:element_type].native_type)}
            errors << "Array #{context} contains one or more more elements that are not of the specified type (#{definition})" unless correct_type
          end
        end
        errors
      end
      
      
      def self.generate_subcontext( context, subindex )
        "#{context||''}[#{subindex}]"
      end
      
      def self.decode_array_proper(value)
        error = []
        if value.is_a?(::Array)
          the_array = value
        elsif value.is_a?(::String)
          # We can decode from JSON...(and that's it for now)
          begin
            the_array = JSON.parse(value)
          rescue Exception => e
            error << "Could not decode the incoming string as an Array. Is it not JSON? (string was: #{value}). Exception: #{e.inspect}"
          end
          unless the_array.is_a? ::Array
            error << "JSON-encoded value doesn't appear to be an array (#{the_array.inspect})" 
            the_array = nil
          end
        else
          error << "Do not know how to decode an array from a #{value.class.name}"
        end
        { :errors => error, :loaded_value=>the_array }
      end
      
      # The incoming value should be an array here, so the only decoding that we need to do 
      # is from the elements (if there's an :element_type defined option).
      def decode( value, context )
        
        #If the value is not an array, decode it first
        tuple = Array.decode_array_proper( value )
        return tuple if sub_definition == nil || tuple[:loaded_value] == nil
        
        element_index = 0
        tuple[:loaded_value] = tuple[:loaded_value].map do |element|
          result = sub_definition.decode( element, Array.generate_subcontext( context, element_index ) )
          
          tuple[:errors] << result[:errors] unless result[:errors].empty?
          element_index += 1
          result[:loaded_value]
        end
        return tuple
      end

      def decode_substructure( decoded_value , context )
        tuple = {:errors => [], :object => [] }
        element_index=0
        decoded_value.each do |item|
          sub_context = Array.generate_subcontext(context,element_index)
          res =  sub_definition.load( item, sub_context )    
          tuple[:object] << res[:object]
          tuple[:errors] += res[:errors] if res[:errors] && res[:errors].size >0   
          element_index +=1                
        end
      
        return tuple
      end
      
      
      #TODO: not clear if this is what's supposed to happen....
      def check_dependencies_substructure(myself,root)
        return [] unless myself
        errors = []
        myself.each do |item|
          errors += sub_definition.check_dependencies(item,root)
        end 
        return errors      
      end
      
      
      def self.native_type
        return ::Array
      end

      def to_debug_subdefinition_hash
        sub_definition.to_debug_hash
      end
    end

  end

