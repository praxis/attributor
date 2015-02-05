require 'date'

module Attributor

  class Time
    include Type

    def self.native_type
      return ::Time
    end

    def self.example(context=nil, options: {})
      return self.load(/[:time:]/.gen, context)
    end

    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      return value if value.is_a?(self.native_type)
      return nil if value.nil?

      return value.to_time if value.respond_to?(:to_time)

      case value
      when ::Integer
        return ::Time.at(value)
      when ::String
        begin
          return ::Time.parse(value)
        rescue ArgumentError => e
          raise Attributor::DeserializationError, context: context, from: value.class, encoding: "Time" , value: value
        end
      else
        raise CoercionError, context: context, from: value.class, to: self, value: value
      end
    end

    def self.dump(value,**opts)
      value.iso8601
    end


  end

end
