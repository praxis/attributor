module Attributor
  class String
    include Type

    def self.native_type
      return ::String
    end

    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      if value.kind_of?(Enumerable)
        raise IncompatibleTypeError,  context: context, value_type: value.class, type: self
      end

      value && String(value)
    rescue
      super
    end

    def self.example(context=nil, options:{})
      if options[:regexp]
        return options[:regexp].gen
      else
        return /\w+/.gen
      end
    end
  end
  
end
