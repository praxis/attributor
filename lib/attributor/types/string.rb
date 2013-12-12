module Attributor
  class String
    include Type

    def self.native_type
      return ::String
    end

    def self.example(context=nil, options={})
      if options[:regexp]
        return options[:regexp].gen
      else
        return /\w+/.gen
      end
    end
  end
end
