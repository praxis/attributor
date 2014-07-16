

module Attributor

  class Integer
    include Type

    EXAMPLE_RANGE = 1000.freeze

    def self.native_type
      return ::Integer
    end


    def self.example(context=nil, options: {})
      validate_options(options)

      # Set default values
      if options[:min].nil? && options[:max].nil?
        min = 0
        max = EXAMPLE_RANGE
      elsif options[:min].nil?
        max = options[:max]
        min = max - EXAMPLE_RANGE
      elsif options[:max].nil?
        min = options[:min]
        max = min + EXAMPLE_RANGE
      else
        min = options[:min]
        max = options[:max]
      end

      # Generate random number on interval [min,max]
      rand(max-min+1) + min
    end

    def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      Integer(value)
    rescue TypeError
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
        # :min must be an integer
        raise AttributorException.new("Invalid range: [#{options[:min].inspect},]") if !options[:min].is_a?(::Integer)
      else
        # Neither :min nor :max were given, noop
      end
      true
    end

  end
end
