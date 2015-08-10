require 'active_support'

require_relative '../exceptions'


module Attributor
  class Class
    include Type

    def self.native_type
      return ::Class
    end

    def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      return @klass || nil if value.nil?

      # Must be given a String object or nil
      unless value.kind_of?(::String) || value.nil?
        raise IncompatibleTypeError,  context: context, value_type: value.class, type: self
      end

      value = "::" + value if value[0..1] != '::'
      result = value.constantize

      # Class given must match class specified when type created using .of() method
      unless @klass.nil? || result == @klass
        raise LoadError, "Error loading class #{value} for attribute with " +
          "defined class #{@klass} while loading #{Attributor.humanize_context(context)}."
      end

      result
    end

    def self.example(context=nil, options:{})
      @klass.nil? ? "MyClass" : @klass.name
    end

    # Create a Class attribute type of a specific Class.
    #
    # @param klass [Class] optional, defines the class of this attribute, if constant
    #
    # @return anonymous class with specified type of collection members
    #
    # @example Class.of(Factory)
    #
    def self.of(klass)
      ::Class.new(self) do
        @klass = klass
      end
    end

    def self.family
      'string'
    end
  end
end
