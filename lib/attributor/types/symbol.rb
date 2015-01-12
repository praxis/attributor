module Attributor
  class Symbol
    include Type

    def self.native_type
      return ::Symbol
    end


    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      value.to_sym
    rescue
      super
    end

    def self.example(context=nil, options:{})
      :example
    end
  end

end
