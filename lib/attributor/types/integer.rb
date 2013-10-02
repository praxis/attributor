

module Attributor

  class Integer
    include Type

    def self.native_type
      return ::Integer
    end


    def self.example(options={},context=nil)
      validate_options(options)

      # Set default values
      min = options[:min] || 0
      max = options[:max] || 1000

      # Generate random number on interval [min,max]
      rand(max-min+1) + min
    end

    def self.load(value)
      if value.is_a?(::String)
        return Integer(value)
      end

      super
    end

    def self.validate_options(options)
      if options.has_key?(:min) && options.has_key?(:max)
        # Both :max and :min must be integers
        raise AttributorException.new("Invalid range: [#{options[:min].inspect}, #{options[:max].inspect}]") if !options[:min].is_a?(::Integer) || !options[:max].is_a?(::Integer)

        # :max cannot be less than :min
        raise AttributorException.new("Invalid range: [#{options[:min].inspect}, #{options[:max].inspect}]") if options[:max] < options[:min]
      elsif !options.has_key?(:min) && options.has_key?(:max)
        # :max must be an integer
        raise AttributorException.new("Invalid range: [, #{options[:max].inspect}]") if !options[:max].is_a?(::Integer)
      elsif options.has_key?(:min) && !options.has_key?(:max)
        # :max must be an integer
        raise AttributorException.new("Invalid range: [#{options[:min].inspect},]") if !options[:min].is_a?(::Integer)
      else
        # Neither :min nor :max were given, noop
      end
    end

  end
end
