# Need types fleshed out:
#   String
#   Integer
#   Boolean
#   DateTime
#   Float
# Will need eventually, but not right now:
#   Hash
#   Array
#     CSV
#     Ids


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

      # Generic decoding and coercion of the attribute.
      def load(value)
        unless value.is_a?(self.native_type)
          raise AttributorException.new("#{self.name} can not load value that is not of type #{self.native_type}. Got: #{value.inspect}.")
        end

        value
      end

      # TODO: refactor this to take just the options instead of the full attribute?
      def validate(value,context,attribute)
        errors = []
        attribute.options.each do |option, opt_definition|
          case option
          when :max
            errors << "#{context} value is larger than the allowed max (#{opt_definition.inspect})" unless value <= opt_definition
          when :min
            errors << "#{context} value is smaller than the allowed min (#{opt_definition.inspect})" unless value >= opt_definition
          when :regexp
            errors << "#{context} value does not match regexp (#{opt_definition.inspect})"  unless value =~ opt_definition
          end
        end
        errors
      end


      # Default, overridable example function
      def example(options=nil, context=nil)
        raise AttributorException.new("#{self} must implement #example")
        # return options[:example] if options.has_key? :example
        # return options[:default] if options.has_key? :default
        # if options.has_key? :values
        #   vals = options[:values]
        #   return vals[rand(vals.size)]
        # end
        # return  nil
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


      def generate_subcontext( context, subname )
        return subname if context.nil? || context == ""
        "#{context}#{Attributor::Attribute::SEPARATOR}#{subname}"
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



    end
  end
end
