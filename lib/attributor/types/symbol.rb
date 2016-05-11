module Attributor
  class Symbol
    include Type

    def self.native_type
      ::Symbol
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      value.to_sym
    rescue
      super
    end

    def self.example(_context = nil, _options: {})
      :example
    end

    def self.family
      String.family
    end
  end
end
