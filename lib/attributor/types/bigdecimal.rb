require 'bigdecimal'

module Attributor
  class BigDecimal 
    include Numeric
    def self.native_type
      ::BigDecimal
    end

    def self.example(_context = nil, options: {})
      BigDecimal("#{/\d{3}/.gen}.#{/\d{3}/.gen}")
    end

    def self.load(value, _context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?
      return value if value.is_a?(native_type)
      return BigDecimal(value, 10) if value.is_a?(::Float)
      BigDecimal(value)
    end

    def self.json_schema_type
      :string
    end

    # Bigdecimal numbers are too big to be represented as numbers in JSON schema
    # The way to do so, is to represent them as strings, but add a 'format' specifying
    # how to parse that (seemingly, there is a 'double' well known type that json API 
    # claims we can use) ... not sure if this is the right one, as technically BigDecimal
    # has very large precision that a double wouldn't be able to fit...
    def self.as_json_schema( shallow: false, example: nil, attribute_options: {} )
      hash = super
      hash[:format] = 'bigdecimal'
      hash
    end
  end
end
