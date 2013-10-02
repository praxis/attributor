

module Attributor

  class Collection
    include Type

    def self.native_type
      return ::Array
    end

  end
end
