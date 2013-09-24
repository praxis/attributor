

module Attributor

  class Integer
    include Type

    def self.native_type
      return ::Integer
    end

    def self.example(options={},context=nil)
      min = options[:min] || 0
      max = options[:max] || 1000

      rand(max-min) + min
    end

    def self.load(value)
      if value.is_a?(::String)
        return Integer(value)
      end

      super
    end

    #def self.validate(value, context, attribute)
    #  super
    #end

  end
end
