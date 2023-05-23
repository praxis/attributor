module Attributor
  # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
  # TODO: should this be a mixin since it is an abstract class?
  module Type
    extend ActiveSupport::Concern

      # Memoized collection classes of specific type (by collection type)
      # i.e., CSV is a Collection of String, which is different from a pure Collection (default)
      # key = membertype class (i.e., String)
      # value = Hash
      #    key = concrete collection class: Attributor::Collection (default) or Attributor::CSV...
      #   value = memoized constructed collection class of the given member type and collection type
      # example: 
      # String => { 
      #   Attributor::Collection => Attributor::Collection.of(String), 
      #   Attributor::CSV => Attributor::CSV.of(String)
      # }
      # It memoized them on in the base Type class, properly serializing access through a mutex
      @_memoized_collection_classes = Hash.new do |h, k|
        h[k] = {}
      end
      @_memoized_collection_classes_mutex = Mutex.new

      class << self
        attr_accessor :_memoized_collection_classes
        def get_memoized_collection_class(member_class, collection_type=Attributor::Collection)
          # No need to serialize on read, Ruby will ensure we can properly read what's there, even if it's being written
          _memoized_collection_classes.dig(member_class,collection_type)
        end
        def set_memoized_collection_class(klass, member_class, collection_type=Attributor::Collection)
          @_memoized_collection_classes_mutex.synchronize do
            _memoized_collection_classes[member_class][collection_type] = klass
          end
        end
      end

    included do
      # Creates a new type that is a collection of this member types
      # By default, T[] is equivalent to Collection.of(T)
      # But you can pass the collection class to use, e.g. T[CSV] is equivalent to CSV.of(T)
      def self.[](collection_type=Attributor::Collection)
        member_class = self
        existing = Attributor::Type.get_memoized_collection_class(member_class,collection_type)
        return existing if existing

        unless self.ancestors.include?(Attributor::Type)
          raise Attributor::AttributorException, 'Collections can only have members that are Attributor::Types'
        end

        # Create and memoize it for non-constructable types here (like we do in Type[])
        new_class = ::Class.new(collection_type) do
          @member_type = member_class
        end
        if self.constructable?
          new_class
        else
          # Unfortunately we cannot freeze the memoized class as it lazily sets the member_attribute inside
          Attributor::Type.set_memoized_collection_class(new_class, member_class, collection_type)
        end
      end
    end
    module ClassMethods
      # Does this type support the generation of subtypes?
      def constructable?
        false
      end

      # Allow a type to be marked as if it was anonymous (i.e. not referenceable by name)
      def anonymous_type(val = true)
        @_anonymous = val
      end

      def anonymous?
        if @_anonymous.nil?
          name.nil? # if nothing is set, consider it anonymous if the class does not have a name
        else
          @_anonymous
        end
      end

      # Generic decoding and coercion of the attribute.
      def load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
        return nil if value.nil?
        unless value.is_a?(native_type)
          raise Attributor::IncompatibleTypeError.new(context: context, value_type: value.class, type: self)
        end

        value
      end

      # Generic encoding of the attribute
      def dump(value, **_opts)
        value
      end

      # TODO: refactor this to take just the options instead of the full attribute?
      # TODO: delegate to subclass
      def validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, attribute) # rubocop:disable Style/OptionalArguments
        errors = []
        attribute.options.each do |option, opt_definition|
          case option
          when :max
            errors << "#{Attributor.humanize_context(context)} value (#{value}) is larger than the allowed max (#{opt_definition.inspect})" unless value <= opt_definition
          when :min
            errors << "#{Attributor.humanize_context(context)} value (#{value}) is smaller than the allowed min (#{opt_definition.inspect})" unless value >= opt_definition
          when :regexp
            errors << "#{Attributor.humanize_context(context)} value (#{value}) does not match regexp (#{opt_definition.inspect})" unless value =~ opt_definition
          end
        end
        errors
      end

      # Default, overridable valid_type? function
      def valid_type?(value)
        return value.is_a?(native_type) if respond_to?(:native_type)

        raise AttributorException, "#{self} must implement #valid_type? or #native_type"
      end

      # Default, overridable example function
      def example(_context = nil, options: {})
        raise AttributorException, "#{self} must implement #example"
      end

      # HELPER FUNCTIONS

      def check_option!(name, definition)
        case name
        when :min
          raise AttributorException, "Value for option :min does not implement '<='. Got: (#{definition.inspect})" unless definition.respond_to?(:<=)
        when :max
          raise AttributorException, "Value for option :max does not implement '>='. Got(#{definition.inspect})" unless definition.respond_to?(:>=)
        when :regexp
          # could go for a respoind_to? :=~ here, but that seems overly... cute... and not useful.
          raise AttributorException, "Value for option :regexp is not a Regexp object. Got (#{definition.inspect})" unless definition.is_a? ::Regexp
        else
          return :unknown
        end

        :ok
      end

      def generate_subcontext(context, subname)
        context + [subname]
      end

      def dsl_compiler
        DSLCompiler
      end

      # By default, non complex types will not have a DSL subdefinition this handles such case
      def compile_dsl(options, block)
        raise AttributorException, 'Basic structures cannot take extra block definitions' if block
        # Simply create a DSL compiler to store the options, and not to parse any DSL
        sub_definition = dsl_compiler.new(options)
        sub_definition
      end

      # Default describe for simple types...only their name (stripping the base attributor module)
      def describe(_root = false, example: nil)
        type_name = Attributor.type_name(self)
        hash = {
          name: type_name.gsub(Attributor::MODULE_PREFIX_REGEX, ''),
          family: family,
          id: id
        }
        hash[:anonymous] = @_anonymous unless @_anonymous.nil?
        hash[:example] = example if example
        hash
      end

      def id
        return nil if name.nil?
        name.gsub('::'.freeze, '-'.freeze)
      end

      def family
        'any'
      end

      # Default no format in case it's a string type
      def json_schema_string_format
        nil
      end
  
      def as_json_schema( shallow: false, example: nil, attribute_options: {} )
        type_name = self.ancestors.find { |k| k.name && !k.name.empty? }.name
        hash = { type: json_schema_type, 'x-type_name': type_name.gsub( Attributor::MODULE_PREFIX_REGEX, '' )}
        # Add a format, if the type has defined
        if hash[:type] == :string && the_format = json_schema_string_format
          hash[:format] = the_format
        end
        # Common options
        hash[:enum] = attribute_options[:values] if attribute_options[:values]
  
        hash
      end

      def describe_option( option_name, option_value )
        return case option_name
        when :description
          option_value
        else
          option_value  # By default, describing an option returns the hash with the specification
        end
      end
      def options
        {}
      end
    end
  end
end
