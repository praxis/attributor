module Attributor
  class String
    include Type

    def self.native_type
      return ::String
    end


    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT)
      # Special handling for Symbols. 
      case value
      when Symbol
        return value.to_s
      else
        super
      end
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
