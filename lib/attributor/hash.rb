

  module Attributor
    
    class Hash < Attribute
  
      def supported_options_for_type
        [:max_size,:id]
      end

      def supports_sub_definition?
        true
      end
      
      def parse_block(&block)
        @sub_definition={}
        self.instance_eval(&block) if block
      end

      # Hash definitions support "attribute", [Type], options, (block)
      # Which can define the attributes possible in the hash and their format (can be recursive)
      # Each attribute will create an attribute and save it on the "definition" piece.
      def attribute(name, incoming_type=nil, incoming_opts={}, &block)

        raise "Attribute #{name} already defined" if sub_definition.has_key? name        
        args = private_decode_args_for_attribute( incoming_type, incoming_opts)
        opts = args[:opts]        
        
        if args[:type]
          type = args[:type]
        else
          unless @inherit_from && @inherit_from.has_key?(name)
            raise "type for #{name} not specified (and attribute with this name cannot be found in the inheritable object): #{@inherit_from.inspect}" 
          end
          type = @inherit_from[name].class
          
          inherited_options = @inherit_from[name].options
          if inherited_options
            opts = inherited_options.merge(args[:opts])
          end 
        end
        
        klass = Attributor.determine_class(type)        
        opts[:inherit_from] = @inherit_from[name] if @inherit_from
        @sub_definition[name] = klass.new(name, opts, &block)
      end
      alias_method :param, :attribute

      def validate_options( options_hash )
        supported_opts = [:max_size]
        validated = common_options_validator_helper(supported_opts, options_hash )
        
        remaining = options_hash.reject{|k,_| validated.include? k }
        remaining.each_pair do|opt,definition|
          case opt
          when :id
            unless ( definition.is_a?(::String) || definition.is_a?(::Symbol))
              raise "Type #{definition} not supported for :id defintion on a Hash" 
            end
          else
            raise "ERROR, unknown option/s (#{opt}) for #{native_type} attribute type"
          end
        end
      end

      def [](name)
        raise "Symbols are not allowed for attribute names, use strings please." if name.is_a? Symbol
        raise "This attribute does not have a sub definition, therefore a named attribute cannot be accessed" unless sub_definition
        sub_definition[name]
      end
      
      def has_key?(name)
        raise "Symbols are not allowed for attribute names, use strings please." if name.is_a? Symbol
        raise "This attribute does not have a sub definition, therefore a named attribute cannot be accessed" unless sub_definition 
        sub_definition.has_key? name
      end   
      
      def private_decode_args_for_attribute( incoming_type, incoming_opts)
        if( incoming_type == nil )
          type = nil
          opts = incoming_opts.dup
        elsif( incoming_type.is_a?(::Hash) )
          type = nil
          opts = incoming_type.dup
        else
          type = incoming_type
          opts = incoming_opts.dup
        end        
        { :type => type, :opts=>opts }
      end
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
      
      def validate(value,context)
        errors = []
        @options.each_pair do |option, definition|
          case option
          when :max_size
            errors << "#{context} has more attributes than the maximum allowed (#{definition})" unless value.keys.size <= definition 
          end
        end
        errors
      end

      
      # Loads the incoming value as a Hash
      # It supports native hash objects, as well as JSON encoded
      def decode(value, context) 
        error = []  
        if( value.is_a? ::String )
          begin
            decoded = JSON.parse(value)
          rescue Exception => e
            error << "Could not decode the incoming string as a Hash. Is it not JSON? (string was: #{value})"
          end
          error << "JSON-encoded value doesn't appear to be a hash" unless decoded.is_a? ::Hash
        elsif( value.is_a? self.native_type )
          decoded = value
        else
          error << "Encoded Hashes for this type is not SUPPORTED! (got: #{value.class.name})"
        end
        
        [ decoded, error ]
      end
      
     def self.native_type
       return ::Hash
     end

      
#      def to_string(numspaces=0)
#        str =  "%-#{numspaces}s HASH(%s,opts=%s)\n" % ["",@name, @options.inspect]
#
#        str += "%-#{numspaces}s {\n" % [" "]  if @sub_definition.size > 0
#        @sub_definition.each do |key, obj |
#          str += "%-#{numspaces}s  %s=>%s" % ["",key, obj.to_string(numspaces+2)]
#        end
#        str += "%-#{numspaces}s }\n" % [""] if @sub_definition.size > 0
#        str
#      end


#########################NEW FOR HASH!!!

      def decode_substructure( decoded_value , context )
        errors = []
        object = {}
        # Validate the individual hash attributes for each defined attribute
        sub_definition.each_pair do |sub_name, sub_attr|    
          sub_context = generate_subcontext(context,sub_name)      
          load_object, load_errors = sub_attr.load( decoded_value[sub_name] , sub_context )
          # Skip saving an empty value key if the incoming decoded value didn't even have it (and it had no default for it)
          object[sub_name] = load_object unless ( !load_object && ! decoded_value.has_key?(sub_name) && !sub_attr.options.has_key?(:default) )
          errors += load_errors unless load_errors.empty?
        end
        [ object, errors ]
      end  
        
      def check_dependencies_substructure(myself,root)
        return [] unless myself
        errors = []
        sub_definition.each_pair do |sub_name, sub_attr|    
          errors += sub_attr.check_dependencies(myself[sub_name],root)
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
      
      def describe_attribute_specific_options
        out = {}
        out[:max_size] = options[:max_size] if options.has_key?(:max_size)
        out[:id] = options[:id] if options.has_key?(:id)
        out
      end
      
      def describe_sub_definition
        out = {}
        sub_definition.map{|k,v| out[k] = v.describe }
        out
      end
      
      def example
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
      
      
    end
  end

