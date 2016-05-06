# Abstract type for the 'numeric' family

module Attributor
  class Numeric
    include Type

    def self.native_type
      raise NotImplementedError
    end

    def self.family
      'numeric'
    end
  end
end
