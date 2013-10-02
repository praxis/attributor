

module Attributor

  class Integer
    include Type

    def self.native_type
      return ::Integer
    end

    def self.example(options={},context=nil)
      # Don't want to allow :min => false or :max => false here, so no ||=
      min = (options[:min] == nil ? 0 : options[:min])
      max = (options[:max] == nil ? 1000 : options[:max])

      # Both :max and :min must be integers
      raise AttributorException.new("Invalid range: [#{min.inspect}, #{max.inspect}]") if !min.is_a?(::Integer) || !max.is_a?(::Integer)

      # :max cannot be less than :min
      raise AttributorException.new("Invalid range: [#{min.inspect}, #{max.inspect}]") if max < min

      # Generate random number on interval [min,max]
      rand(max-min+1) + min
    end

    def self.load(value)
      if value.is_a?(::String)
        return Integer(value)
      end

      super
    end

  end
end
