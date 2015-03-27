# Abstract type for the 'temporal' family

module Attributor

  class Temporal
    include Type

    def self.native_type
      raise NotImplementedError
    end

    def self.family
      'temporal'
    end

    def self.dump(value,**opts)
      value && value.iso8601
    end

  
  end
end
