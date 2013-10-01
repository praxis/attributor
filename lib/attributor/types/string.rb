module Attributor
  class String
    include Type

    def self.native_type
      return ::String
    end

    def self.example(options={})
      if options[:regexp]
        return options[:regexp].gen
      else
        return /[:sentence:]/.gen
      end
    end
  end
end
