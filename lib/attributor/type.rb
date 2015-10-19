module Attributor

  # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
  # TODO: should this be a mixin since it is an abstract class?
  module Type

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods

      # Does this type support the generation of subtypes?
      def constructable?
        false
      end

      # Generic decoding and coercion of the attribute.
      def load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
        return nil if value.nil?
        unless value.is_a?(self.native_type)
          raise Attributor::IncompatibleTypeError, context: context, value_type: value.class, type: self
        end

        value
      end

      # Generic encoding of the attribute
      def dump(value,**opts)
        value
      end

      # TODO: refactor this to take just the options instead of the full attribute?
      # TODO: delegate to subclass
      def validate(value,context=Attributor::DEFAULT_ROOT_CONTEXT,attribute)
        errors = []
        attribute.options.each do |option, opt_definition|
          case option
          when :max
            errors << "#{Attributor.humanize_context(context)} value (#{value}) is larger than the allowed max (#{opt_definition.inspect})" unless value <= opt_definition
          when :min
            errors << "#{Attributor.humanize_context(context)} value (#{value}) is smaller than the allowed min (#{opt_definition.inspect})" unless value >= opt_definition
          when :regexp
            errors << "#{Attributor.humanize_context(context)} value (#{value}) does not match regexp (#{opt_definition.inspect})"  unless value =~ opt_definition
          end
        end
        errors
      end

      # Default, overridable valid_type? function
      def valid_type?(value)
        return value.is_a?(native_type) if respond_to?(:native_type)

        raise AttributorException.new("#{self} must implement #valid_type? or #native_type")
      end

      # Default, overridable example function
      def example(context=nil, options:{})
        raise AttributorException.new("#{self} must implement #example")
      end


      # HELPER FUNCTIONS


      def check_option!(name, definition)
        case name
        when :min
          raise AttributorException.new("Value for option :min does not implement '<='. Got: (#{definition.inspect})") unless definition.respond_to?(:<=)
        when :max
          raise AttributorException.new("Value for option :max does not implement '>='. Got(#{definition.inspect})") unless definition.respond_to?(:>=)
        when :regexp
          # could go for a respoind_to? :=~ here, but that seems overly... cute... and not useful.
          raise AttributorException.new("Value for option :regexp is not a Regexp object. Got (#{definition.inspect})") unless definition.is_a? ::Regexp
        else
          return :unknown
        end

        return :ok
      end


      def generate_subcontext(context, subname)
        context + [subname]
      end

      def dsl_compiler
        DSLCompiler
      end

      # By default, non complex types will not have a DSL subdefinition this handles such case
      def compile_dsl( options, block )
        raise AttributorException.new("Basic structures cannot take extra block definitions") if block
        # Simply create a DSL compiler to store the options, and not to parse any DSL
        sub_definition=dsl_compiler.new( options )
        return sub_definition
      end

      # Default describe for simple types...only their name (stripping the base attributor module)
      def describe(root=false, example: nil)
        type_name = Attributor.type_name(self)
        hash = {
          name: type_name.gsub(Attributor::MODULE_PREFIX_REGEX, ''),
          family: self.family,
          id: self.id
        }
        hash[:example] = example if example
        hash
      end

      def id
        return nil if self.name.nil?
        self.name.gsub('::'.freeze,'-'.freeze)
      end

      def family
        'any'
      end

    end
  end
end
