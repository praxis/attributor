require 'bigdecimal'

module Attributor

  class BigDecimal
    include Type

    def self.native_type
      return ::BigDecimal
    end

    def self.example(context=nil, **options)
      return ::BigDecimal.new("#{/\d{3}/.gen}.#{/\d{3}/.gen}")
    end

    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      return nil if value.nil?
      return value if value.is_a?(self.native_type)
      return BigDecimal(value)
    end

  end

end

