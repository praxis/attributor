# frozen_string_literal: true

module Attributor
  class String
    include Type

    def self.native_type
      ::String
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      raise IncompatibleTypeError, context: context, value_type: value.class, type: self if value.is_a?(Enumerable)

      value && String(value)
    rescue StandardError
      super
    end

    def self.example(_context = nil, options: {})
      if options[:regexp]
        begin
          # It may fail to generate an example, see bug #72.
          options[:regexp].gen
        rescue StandardError => e
          format('Failed to generate example for %<regexp>s : %<msg>s', regexp: options[:regexp].inspect, msg: e.message)
        end
      else
        /\w+/.gen
      end
    end

    def self.family
      'string'
    end
  end
end
