module Attributor
  class Hash
    include Type

    def self.native_type
      return ::Hash
    end

    def self.example(context=nil, options={})
      ::Hash.new
    end

  end
end
