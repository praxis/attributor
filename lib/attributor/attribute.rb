
  module Attributor
    
    def self.find_class(name)
      klass = const_get(name) if const_defined?(name)
      raise "Could not find class with name #{name}" unless klass
      raise "Could not find attribute type for: #{name} [klass: #{klass.name}]"  unless  klass < Attributor::Attribute
      klass
    end
    # IT returns the correct attribute class to be used for instantiation
    # If it doesn't derive from Attribute, we'll assume there is one with the same name within the Attributor module
    def self.determine_class(type)
      return type if type < Attributor::Attribute    
      demodulized_class_name = type.name.split("::").last # TOO EXPENSIVE?
      Attributor.find_class(demodulized_class_name)
    end
    
    # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
    # TODO: should this be a mixin since it is an abstract class?
    class Attribute
      
      # hierarchical separator string for composing human readable attributes 
      SEPARATOR = '.'
      
      attr_reader :name, :options, :inherit_from, :sub_definition
      
      # @name: name of the attribute
      # @options: metadata about the attribute (available options are attribute type specific)
      # @block: code definition about the sub-structure of the attribute (nil if a leaf attribute)
      def initialize(name, opts={}, &block)
        # Save the related media type subtree and root special options, if passed
#        @related_media_type_subtree = options.delete(:related_media_type_subtree)
#        @related_media_type_root = options.delete(:related_media_type_root)
#        @is_required = options.delete(:required) || false # Default: not required
#        raise "required param must be a boolean" unless ( @is_required.is_a?(TrueClass) || @is_required.is_a?(FalseClass) )

        @name = name
        @options = opts.dup
        @inherit_from = @options.delete(:inherit_from) # AttributeType object to inherit options/subdefinitions from
#        @type_class_name = self.class.name.split('::').last #Original class definition (our naming)
        processed = validate_universal_options
  
        remaining = @options.reject{|key,_| processed.include? key } 
        validate_options( remaining ) if self.respond_to? :validate_options
#        if block_given? # Construct the full attribute definition (which might include parsing the block further for sub-objects)
#          @sub_definition = {} #For attributes that can accept a block with further structure
          parse_block(&block) #if block_given?
#        end
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
      
      
      def validate_universal_options
        universal_options = [:required,:default,:values,:description,:required_if]
        validated = []
        universal_options.each do|opt|
          if ( @options.has_key?(opt) ) # Validate the option if it exists
            definition = @options[opt]
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
              raise "Required cannot be enabled in combination with :default" if definition == true && @options.has_key?(:default) 
            when :required_if
              raise "Required if must be a String, a Hash definition or a Proc" unless definition.is_a?(::String) || definition.is_a?(::Hash) || definition.is_a?(::Proc)
            end
          end
        end
        validated
      end
      # Native type for the attribute (based on the derived class' native type)
      def native_type
        self.class.native_type
      end
      
      def parse_block(&block)
        raise "This attribute class (#{self.class.name}) does not implement attribute sub-definition parsing. Please implement 'parse_block' for that type" if block_given?
      end
            
      # Top-level loading of the attribute. It loads it and then checks for requirement dependencies      
      def parse(value)
        object, errors = load(value,nil)      
        dependency_errors = check_dependencies(object,object)
        dependency_errors.each {|error| errors << error }
        object = nil unless errors.empty?
        [ object, errors ]
      end
            
      # Generic load, coercion and validation of the attribute
      # Explicit attribute types need to implement the "decode", "validate_type", "validate" and "decode_substructure" 
      def load(value,context)
  
        return [ nil, ["Attribute #{context} is required"] ] if( value.nil? && options[:required] )       
        value = options[:default] if ( value.nil? && options.has_key?(:default) )
        
        return [ nil , [] ]  if value.nil? #Nothing to decode further if nil
        loaded_value, errors = decode(value,context)
        puts "LOADERR: #{errors.inspect}"          
        puts "LOADVAL: #{loaded_value.inspect}"          
        
        if errors.empty?
          errors += validate_type(loaded_value,context) 
          if options[:values] && !options[:values].include?(loaded_value) 
            errors << "value #{value} is not within the allowed values=#{options[:values].join(',')} "
          end
          errors += validate(loaded_value,context) if self.respond_to? :validate
          if @sub_definition.nil?
            object = loaded_value
          else
            object, sub_errors = decode_substructure( loaded_value, context )
            errors += sub_errors
          end
        else
          object = nil
        end
        [ object, errors ]
      end
      
      def check_dependencies(myself, root)
        errors = []
        # Checks any conditional dependencies of this attribute (against the root object) and returns an array of errors
        # Checks the dependencies for this attribute itself
        if options.include? :required_if
          errors = errors + check_dependency( options[:required_if], myself, root )
        end

        # Checks any dependencies for the sub attributes
        errors = errors + check_dependencies_substructure(myself,root) unless sub_definition.nil?
        return errors
      end
      
      def fetch_related_value( dotted_name, root )
        segments = dotted_name.split(SEPARATOR)
        segments.inject(root){|base,segment| (base == nil ? nil : base[segment] ) } 
      end
      private :fetch_related_value
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
      # By default the object value coming in, is already loaded correctly.
      # i.e., for simple types in JSON payload, or for simple strings in the URL params.
      # Attribute types that are more complex, might want to get the incoming value and decode it into the proper object before processing
      # TODO: Need to build error handling/reporting with this function...should return error msg
      def decode( value, context )
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
      # Object representation of the attribute for doc generation purposes
      # Note: if we don't want to duplicate the name inside the hash, we can simply 
      # not include it (it would be in the parent key)
      def to_doc_hash
        hash = {:name => @name, :type => @type_class_name, :required=> !!@options[:required] , :options => @options.dup}
        # Make sure we don't leak skeletor types (and convert it to the native one) if there's an element_type defined
        type = @options[:element_type]
        hash[:options][:element_type] = type.native_type if type
        
        
        if @sub_definition && @sub_definition.keys.size > 0
          hash[:definition] = {}
          @sub_definition.each do |k,v|
            hash[:definition][k] = v.to_doc_hash
          end
        end
        hash
      end
      def to_debug_hash
        hash = {:name => @name, :type => self.class.name.split('::').last , :options => @options.dup}
        # Make sure we don't leak skeletor types (and convert it to the native one) if there's an element_type defined
        type = @options[:element_type]
        hash[:options][:element_type] = type.native_type if type
                
        hash[:definition] = to_debug_subdefinition_hash if sub_definition
        hash
      end

      
    end
  end
