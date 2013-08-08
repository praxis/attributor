
module Attributor
    
    # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
    # TODO: should this be a mixin since it is an abstract class?
    module Base
      # hierarchical separator string for composing human readable attributes 
      SEPARATOR = '.'
      
      def self.included( klass )
        klass.extend(ClassMethods)
      end

      module ClassMethods
      
        ########
        # @!group Public interface to an Attributor "Type" class
        
        # Base entry point for describing an attribute (and its substructure if any)
        def describe(definition,show_subattributes=true)
          puts "BASE DESCRIBE FOR #{self.name}"
          hash = {:type => self.name.split('::').last }

          # It handles the options part of the description
          universal_options = [:required,:default,:values,:description,:required_if]

          hash.merge!(self.describe_universal_options(definition.options))
          # Report only if they are required
          hash.delete(:required) unless (definition.options.has_key?(:required) && definition.options[:required]) 
          hash.merge!(self.describe_common_options(definition.options))
          hash.merge!(self.describe_attribute_specific_options(definition.options)) if self.respond_to?(:describe_attribute_specific_options)
          unless definition.attributes.empty?
            puts "BASE DESCRIBING SUBSTRUCT using #{definition}"
            hash[:attributes] = definition.describe_attributes if show_subattributes
          end
          hash        
        end
      
        
        # Top-level loading of the attribute. It loads/decodes it and then validates it (including checks for requirement dependencies)
        def parse(value, context, attribute )
          puts "PARSE : #{value}"
          object, errors = load(value, context, attribute)
          return [ nil , errors ] if errors.any?
          
          errors += new_validate(object, context, attribute) 
          [ object, errors ]
        end

      
        # Generic decoding and coercion of the attribute. This can change the contents of the incoming value (i.e., set sub-attriutes etc...)
        # Loads the incoming value as a Hash
        # It supports native hash objects, as well as JSON encoded
        def load(value, context, attribute) 
  #        puts "STRUCT DECODING: #{value} (ATTR: #{attribute.inspect})"
  #        puts "Context: #{context}"
          error = []  
          
          # Decode the value unless it's already of the right type
          unless value.is_a? native_type
            value = new_decode( value, attribute)
          end
          
          #Inject default if decoded value was nil
          if value.nil?
            value = attribute.options[:default] if attribute.options[:default]
          end

          attribute.attributes.each do |sub_name, sub_attr| 
            v = value.has_attribute?(sub_name) ? value.get_attribute(sub_attr) : Attributor::UNSET
            sub_context = generate_subcontext(context,sub_name)
            o, e = sub_attr.load(v,sub_context, sub_attr )
            if e.empty?
              value.set_attribute(sub_name, o ) if v == o # If it was different, set it.
            else
              error += e
            end
          end

          [ value, error ]
        end
      
      
        # Validates stuff and checks dependencies
        def new_validate( object, context, attribute, parent )
          errors=[]
          
          if object.nil?
            # Requirement check
            return ["Attribute #{context} is required"] if attribute.options[:required]
          end
          
          errors += validate_type(object,context) 
          if attribute.options[:values] && !attribute.options[:values].include?(object) 
            errors << "value #{object} is not within the allowed values=#{definition.options[:values].join(',')} "
          end
          # Only validate this node for type-specific options...do not recurse (as we'll recurse in a moment)
          errors += validate(object,context,attribute) if self.respond_to? :validate

          attribute.attributes.each do |sub_name, sub_attr| 
            sub_context = generate_subcontext(context,sub_name)  
            errors += sub_attr.type.new_validate( object.fetch_attribute(sub_name,Attributor::UNSET), sub_context , sub_attr, object, sub_name )
          end
          # TODO: What do we do if there are incoming attr names that don't match the definition? ... silently skip?...
          
          if parent.nil? #Check conditional dependencies only once all has been validated (i.e., loaded with defaults and all) (at the top level)
            errors += attribute.check_dependencies(object,object,attribute)  
          end
          
          errors
        end
        
        # Default, overridable example function
        def example(options)
          return options[:example] if options.has_key? :example
        
          return options[:default] if options.has_key? :default
          if options.has_key? :values
            vals = options[:values]
            return vals[rand(vals.size)] 
          end
          return  nil 
        end      
      
        # @!endgroup
        
#      attr_reader :inherit_from
      
      def has_sub_definition?
        false
      end
      
        
      def supported_options_for_type
        return []
        raise "Type subclasses need to override this and return an array of option names that they support (that fall within the common ones). Otherwise they can fully override validate_options for custom option validation"
      end
      
      def validate_options( options_hash )
        # Right now, we only support regex so we can use the common helper for it
        unsupported_opts =  options_hash.keys - common_options_validator_helper(supported_options_for_type, options_hash )
        raise "ERROR, unknown option/s (#{unsupported_opts.join(',')}) for #{native_type} attribute type" unless (unsupported_opts).empty?
      end
            
      def validate_universal_options( incoming_options )
        universal_options = [:required,:default,:values,:description,:required_if,:example]
        validated = []
        universal_options.each do|opt|
          if ( incoming_options.has_key?(opt) ) # Validate the option if it exists
            definition = incoming_options[opt]
            validated << opt
            case opt
            when :values
              raise "Allowed set of values requires an array. Got (#{definition})" unless definition.is_a? ::Array
            when :default
              raise "Default value doesn't have the correct type. Requires (#{native_type.name}). Got (#{definition})" unless definition.is_a? native_type
            when :description
              raise "Description value must be a string. Got (#{definition})" unless definition.is_a? ::String
            when :required
              raise "Required must be a boolean" unless !!definition == definition # Boolean check
              raise "Required cannot be enabled in combination with :default" if definition == true && incoming_options.has_key?(:default) 
            when :required_if
              raise "Required_if must be a String, a Hash definition or a Proc" unless definition.is_a?(::String) || definition.is_a?(::Hash) || definition.is_a?(::Proc)
              raise "Required_if cannot be specified together with :required" if options[:required]
            when :example
              unless definition.is_a?(native_type) || definition.is_a?(Regexp) 
                raise "Invalid example type (got: #{definition.class.name}) for type (#{native_type.inspect}). It must always match the type of the attribute (except if passing Regex that is allowed for some types)" 
              end
            end
          end
        end
        validated
      end
      # Native type for the attribute (based on the derived class' native type)
#      def native_type
#        self.class.native_type
#      end
      
#      def compile_dsl( block, options )
#      end

      # By default, there's no substructure (unless overriden) ... so no decoding needed, and no errors checking dependencies
      def decode_substructure( decoded_value , context )
        return [ decoded_value, [] ]
      end
      def check_dependencies_substructure(myself,root,attribute)
        []
      end

      def check_dependencies(myself, root, attribute)
        errors = []
        # Checks any conditional dependencies of this attribute (against the root object) and returns an array of errors
        # Checks the dependencies for this attribute itself
        if attribute.options.include? :required_if
          errors = errors + check_dependency( attribute.options[:required_if], myself, root )
        end

        # Checks any dependencies for the sub attributes
        errors = errors + check_dependencies_substructure(myself,root,attribute) unless attribute.type < Attributor::Struct #TODO: Change this to check if it has a "sub-structure" type module ...
        return errors
      end

      # checks a single dependency condition based on a loaded attribute
      def check_dependency( condition_spec, value, root )
        return [] if value
        errors = []
        case condition_spec
        when ::String          
          dependent_value = fetch_related_value(condition_spec,root)
          errors << "value for #{name} required when #{condition_spec} is defined" unless dependent_value.nil?
        when ::Hash
          raise "not more than 1 condition supported right now (got: #{condition_spec.inspect})" if condition_spec.keys.size > 1
          dependent_attribute = condition_spec.keys.first
          target_value = condition_spec[dependent_attribute]
          case target_value
          when ::String
            # 'some.name' => 'some_value'
            dependent_value = fetch_related_value(dependent_attribute,root)
            errors << "value for #{name} required since #{dependent_attribute}=#{target_value}" if !dependent_value.nil? && dependent_value == target_value
           
          when ::Regexp
            # 'some.name' => /regexp/
            dependent_value = fetch_related_value(dependent_attribute,root)
            errors << "value for #{name} required since #{dependent_attribute} matches #{target_value.inspect}" if !dependent_value.nil? &&  dependent_value =~ target_value
          when ::Proc
            # 'some.name' => Proc.new{|value| return true or false}
            dependent_value = fetch_related_value(dependent_attribute,root)
            errors << "value for #{name} required since the defined Proc condition returns true when passing the dependent value: #{dependent_value}" if !dependent_value.nil? && target_value.call(dependent_value) == true
          else
            raise "this type of target condition for a Hash dependency is not supported" 
          end
          errors
        else
          raise "This type of condition definition is not currenty supported"
        end
        return errors
      end
      
      
      def fetch_related_value( dotted_name, root )
        segments = dotted_name.split(SEPARATOR)
        segments.inject(root){|base,segment| (base == nil ? nil : base[segment] ) } 
      end
      
      

      # By default the object value coming in, is already loaded correctly.
      # i.e., for simple types in JSON payload, or for simple strings in the URL params.
      # Attribute types that are more complex, might want to get the incoming value and decode it into the proper object before processing
      # TODO: Need to build error handling/reporting with this function...should return error msg
      def load( value, context , attribute)
        [ value, [] ]
      end
      
      # Base type validation which simply compares the type of the passed value to the native type of the attribute
      # TODO: should the comparison be "inherits from", rather than "exactly the same class"?
      def validate_type(value,context)
        if !( value.is_a? self.native_type)
          return ["Received value for #{context} has the wrong type! (got:#{value.class} expected:#{self.native_type})"]
        else
          return []
        end
      end
      
      # HELPER FUNCTIONS  
      

      # A helper function that any attribute can use to reduce boilerplate for verifying options 
      # that are common across them. For now, we have 
      # min and max => which must be integers
      # values => which must be an array (of whatever type is expected)
      # TODO: should this return some sort of errors rather than raising?
      def common_options_validator_helper(keys_to_validate, options_hash)
        validated = []
        keys_to_validate.each do|opt|
          if ( definition = options_hash[opt] ) # Validate the option if it exists
            validated << opt
            case opt
            when :min
              raise "Integer required for :min option in Integer attribute. Got (#{definition})" unless definition.is_a? ::Integer
            when :max
              raise "Integer required for :max option in Integer attribute. Got (#{definition})" unless definition.is_a? ::Integer
            when :regexp
              raise "Regexp option requires a ruby Regexp object. Got (#{definition})" unless definition.is_a? ::Regexp
            when :max_size
              raise "Max size size option requires an Integer. Got (#{definition})" unless definition.is_a? ::Integer
            else
              raise "ERROR, option (#{opt}) not supported in the common options validator."
            end
          end
        end
        return validated
      end
      
      def generate_subcontext( context, subname )
        return subname if context.nil? || context == ""
        "#{context}#{Attributor::Attribute::SEPARATOR}#{subname}"
      end
      

      
      def describe_universal_options(options)
        universal_options = [:required,:default,:values,:description,:required_if]
        out = {}
        universal_options.each do |opt_sym|
          out[opt_sym] = options[opt_sym] if options.has_key?(opt_sym)
        end
        out
      end
      
      def describe_common_options(options)
        common_options = [:min,:max,:regexp,:max_size]
        out = {}
        common_options.each do |opt_sym|
          out[opt_sym] = options[opt_sym] if options.has_key?(opt_sym)
        end
        out
      end
      
#      def self.options
#        @options
#      end
      
      
      def dsl_compiler
        DSLCompiler
      end
      
      # By default, non complex types will not have a DSL subdefinition this handles such case
      def compile_dsl( options, block )
        raise "Basic structures cannot take extra block definitions" if block
        # Simply create a DSL compiler to store the options, and not to parse any DSL
        sub_definition=dsl_compiler.new( options )
        return sub_definition
      end
      

         
      end   
    end
  end
