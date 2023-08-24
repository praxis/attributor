# Represents a plain old boolean type. TBD: can be nil?
#
require_relative '../exceptions'

require 'date'

module Attributor
  class DateTime
    include Temporal

    def self.native_type
      ::DateTime
    end

    def self.example(context = nil, options: {})
      load(Faker::Date.in_date_period, context)
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      # We assume that if the value is already in the right type, we've decoded it already
      return value if value.is_a?(native_type)
      return value.to_datetime if value.respond_to?(:to_datetime)
      return nil unless value.is_a?(::String)

      # TODO: we should be able to convert not only from String but Time...etc
      # Else, we'll decode it from String.
      begin
        ::DateTime.parse(value)
      rescue ArgumentError
        raise Attributor::DeserializationError.new(context: context, from: value.class, encoding: 'DateTime', value: value)
      end
    end

    def self.json_schema_string_format
      :'date-time'
    end
  end
end
