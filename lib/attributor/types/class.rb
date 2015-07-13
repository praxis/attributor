require_relative '../exceptions'

module Attributor
  class Class
    include Type

    def self.native_type
      return ::Class
    end

    def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      unless value.kind_of?(::String) || value.nil?
        raise IncompatibleTypeError,  context: context, value_type: value.class, type: self
      end

      value = "::" + value if value[0..1] != '::'

      value && eval(value)
    rescue
      super
    end

    def self.example(context=nil, options:{})
      "MyClass"
    end

    def self.family
      'string'
    end

  end
end
