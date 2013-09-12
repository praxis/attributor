
module Attributor

  # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
  # TODO: should this be a mixin since it is an abstract class?
  module Type
    # hierarchical separator string for composing human readable attributes
    SEPARATOR = '.'

    def self.included( klass )
      klass.extend(ClassMethods)
    end

    module ClassMethods

      # @!group Tested

      # ===================================
      # Tested Stuff
      # ===================================

      # Generic decoding and coercion of the attribute.
      def load(value, context, attribute)
        unless value.is_a?(self.native_type)
          raise "#{self.name} can not load value that is not of type #{self.native_type}. Got: #{value.inspect}."
        end

        value
      end

      # @endgroup

      # ===================================
      # Stuff in Limbo
      # ===================================

      def validate(subject,*stuff)
        []
      end

      # ===================================
      # Untested Stuff
      # ===================================


      ########
      # @!group Public interface to an Attributor "Type" class



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
      #def load( value, context , attribute)
      #  [ value, [] ]
      #end

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


      def check_option!(name, definition)
        case name
        when :min
          raise "Integer required for :min option in Integer attribute. Got (#{definition})" unless definition.is_a? ::Integer
        when :max
          raise "Integer required for :max option in Integer attribute. Got (#{definition})" unless definition.is_a? ::Integer
        when :regexp
          raise "Regexp option requires a ruby Regexp object. Got (#{definition})" unless definition.is_a? ::Regexp
        when :max_size
          raise "Max size size option requires an Integer. Got (#{definition})" unless definition.is_a? ::Integer
        else
          return :unknown
        end
        
        return :ok
      end

   
      def generate_subcontext( context, subname )
        return subname if context.nil? || context == ""
        "#{context}#{Attributor::Attribute::SEPARATOR}#{subname}"
      end

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
