

module Attributor
  module Model 
    
    def self.included( klass )
      klass.module_eval do
        include Attributor::Base
      end
      klass.extend(ClassMethods)
    end
    
    module ClassMethods

      def example(options)
        return options[:example] if options.has_key? :example
        return super if options.has_key?(:default) || options.has_key?(:value)
        
        result = {}
        count =  options[:max_size] || -1
        sub_definition.each do |k,v|
          result[k] = v.example
          break if count == 0 # Do not generate more keys than the max size allowed
          count -= 1
        end
        result
      end     
       
      def describe(definition,show_subattributes=false)
        super(definition,false)
      end

      # method to only define the block of attributes for the model
      # This will be a lazy definition. So we'll only save it in an instance class var for later.
      def attributes(opts={},&block)
        raise "There is no getter for attributes here (go through definition.attributes)" unless block_given?
        @saved_dsl = block
        @saved_options = opts
      end
           
      # Returns the "compiled" definition for the model.
      # By "compiled" I mean that it will create a new Compiler object with the saved options and saved block that has been passed in the 'attributes' method. This compiled object is memoized (remember, there's one instance of a compiled definition PER MODEL CLASS).
      def definition( options=nil, block=nil )
        raise "Blueprint structures cannot take extra block definitions" if block
        raise "Models cannot take additional attribute options (options already defined in the Model )" if options
         
        unless @compiled_class_block
          @compiled_class_block = DSLCompiler.new(@saved_options)
          @compiled_class_block.parse(&@saved_dsl) if @saved_dsl
        end
        @compiled_class_block
      end
        
        
      # Native type of a Struct (or derived class) its it's own class type.
      def native_type
        self
      end
      ########################

      def supports_sub_definition?
        true
      end

      #TODO: Rethink the helper function for common options, the supported_options_for_type method...etc...should it be done/inherited differently? 
      def supported_options_for_type
        [:max_size,:id] #TODO: I don' tthink the model type needs :max_size...
      end

      # Given a hash of option name to option values, it validates that:
      # 1- The option name is one of the supported one for this type. I.e., that :max_size is supported
      # 2- That the definition of the option,that is the value for it, is correct. I.e. that :max_size gets an Integer
      def validate_options( options_hash )
        supported_opts = [:max_size]
        validated = common_options_validator_helper(supported_opts, options_hash )
        
        remaining = options_hash.reject{|k,_| validated.include? k }
        remaining.each_pair do|opt,definition|
          case opt
          when :id
            # TODO: Rethink if we need to continue supporting this option: which means this attribute is a "PK" of sorts...
            unless ( definition.is_a?(::String) || definition.is_a?(::Symbol))
              raise "Type #{definition} not supported for :id defintion on a Hash" 
            end
          else
            raise "ERROR, unknown option/s (#{opt}) for #{native_type} attribute type"
          end
        end
      end

      # Retrieves the definition of one of the named subattributes.
      def [](name)
        raise "Symbols are not allowed for attribute names, use strings please." if name.is_a? Symbol
        raise "This attribute does not have a sub definition, therefore a named attribute cannot be accessed" unless sub_definition
        sub_definition[name]
      end
      
      # Returns true if we have a definition for a name subattribute
      def has_key?(name)
        raise "Symbols are not allowed for attribute names, use strings please." if name.is_a? Symbol
        raise "This attribute does not have a sub definition, therefore a named attribute cannot be accessed" unless sub_definition 
        sub_definition.has_key? name
      end   
      
    
      # Validates an incoming value (corresponding to this native type) only against the defined options. 
      # For example, if there's an option (i.e., :max_size=>4) that said that instances of this model type can only 
      # have 4 attributes defined. This function would validate that the incoming model value has no more than 4 attributes.
      # TODO: verify, I belive we're guaranteed that the incoming value is of native_type of this model?...
      # It returns an array of errors (human string explanations for which it might not have passed validation). Empty array means "passed".
      def validate(value,context,definition)
        errors = []
        definition.options.each_pair do |option, opt_value|
          case option
          when :max_size
            #TODO: completely remove the max_size option
            #errors << "#{context} has more attributes than the maximum allowed (#{opt_value})" unless value.attributes.size <= opt_value 
          end
        end
        errors
      end
      
      def from_hash(hash_value, attribute=self.definition)
        puts "MODEL: DECODING FROM HASH >>#{value}<<"
        attr_instance = new_for_attribute(attribute)
        
        attribute.attributes.each do |sub_name, sub_attr| 
          attr_instance.update_attribute( sub_name, hash_value.fetch(sub_name) ) #TODO: handle when name doesn't exist...etc..and unSET?
        end          
        #TODO/NOTE: we're not gonna transfer any extra hash attributes that are not part of the definition...
        attr_instance
      end
      
      def new_for_attribute( attribute )
        self.new
      end
      
      
      # Generic decoding and coercion of the attribute. This can change the contents of the incoming value (i.e., set sub-attriutes etc...)
      # Loads the incoming value as a Hash
      # It supports native hash objects, as well as JSON encoded
      def new_decode(value, context, attribute) 
#        puts "STRUCT DECODING: #{value} (ATTR: #{attribute.inspect})"
#        puts "Context: #{context}"
        
        decoded = if( value.is_a? native_type )
          value
        elsif( value.is_a? ::Hash )
          from_hash(value,attribute)
        elsif( value.is_a? ::String )
          # TODO: terrible structure...move things around...
          json_decoded=nil
          begin
            json_decoded = JSON.parse(value)
          rescue Exception => e
            error << "Could not decode the incoming string as a #{self.name}. Is it not JSON? (string was: #{value})\nException: #{e.inspect}"
          end
           from_hash(json_decoded,attribute)
        elsif( value == Attributor::UNSET )
          #HANDLE DEFAULT
          raise "UNHANDLED!"
        else        
          raise "Cannot decode a model from type value: #{value.class.name}"
        end
        
        return decoded
      end


#      def decode_substructure( decoded_value , context , attribute )
#        errors = []
#        # Validate the individual hash attributes for each defined attribute
#        # TODO: But only if they are 'not-primitives/already-decoded'...otherwise we'll try to re-parse them again...waste of time!
#        attribute.attributes.each_pair do |sub_name, sub_attr| 
#          puts "SUBNAME: #{sub_name} => SUBATTR: #{sub_attr.inspect}"
#          sub_context = generate_subcontext(context,sub_name)      
#          load_object, load_errors = sub_attr.parse( decoded_value.send(sub_name) , sub_context )
#          # Skip saving an empty value key if the incoming decoded value didn't even have it (and it had no default for it)
#          decoded_value.send("#{sub_name}=", load_object) unless ( !load_object && ! decoded_value.respond_to?(sub_name) && !sub_attr.options.has_key?(:default) )
#          errors += load_errors unless load_errors.empty?
#        end
#        [ decoded_value, errors ]
#      end  
        
      def check_dependencies_substructure(myself,root,attribute)
        return [] unless myself
        errors = []
        attribute.attributes.each_pair do |sub_name, sub_attr|    
#          puts "?????????????#{sub_name} => #{sub_attr}"
          errors += sub_attr.check_dependencies( myself.send(sub_name) , root , sub_attr )
        end
        return errors      
      end
        
      def to_debug_subdefinition_hash
        out = {}
        sub_definition.each_pair do |name,attr|
          out[name] = attr.to_debug_hash
        end 
        out
      end
      
      def describe_attribute_specific_options(options)
        out = {}
        out[:max_size] = options[:max_size] if options.has_key?(:max_size)
        out[:id] = options[:id] if options.has_key?(:id)
        out
      end
      
      def describe_sub_definitionXXXXXXXX
        out = {}
        sub_definition.map{|k,v| out[k] = v.describe }
        out
      end
      

     
     
     
      #     def private_decode_args_for_attribute( incoming_type, incoming_opts)
      #       if( incoming_type == nil )
      #         type = nil
      #         opts = incoming_opts.dup
      #       elsif( incoming_type.is_a?(::Hash) )
      #         type = nil
      #         opts = incoming_type.dup
      #       else
      #         type = incoming_type
      #         opts = incoming_opts.dup
      #       end        
      #       { :type => type, :opts=>opts }
      #     end
      ############## TODO Can we get rid of this "id" business here?...
      ##############      # Special case for an attribute that is defined as an 'id' param in the media-type
      ##############      def id( name, type=nil, opts={}, &block )
      ##############        attribute(name, type, opts.merge(:id=>true), &block )
      ##############      end
      ##############      
      ##############      # Gets the attribute definition of the id for the media_type
      ##############      def get_id_definition
      ##############        @sub_definition[@id_name]
      ##############      end 
    end
      
        
  end
end
