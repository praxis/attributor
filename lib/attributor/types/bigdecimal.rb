require 'bigdecimal'

module Attributor
  class BigDecimal < Numeric
    def self.native_type
      ::BigDecimal
    end

    def self.example(_context = nil, options: {})
      ::BigDecimal.new("#{/\d{3}/.gen}.#{/\d{3}/.gen}")
    end

    def self.load(value, _context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?
      return value if value.is_a?(native_type)
      return BigDecimal(value, 10) if value.is_a?(::Float)
      BigDecimal(value)
    end
  end
end
