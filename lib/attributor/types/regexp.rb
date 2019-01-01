# frozen_string_literal: true

require_relative '../exceptions'

module Attributor
  class Regexp
    include Type

    def self.native_type
      ::Regexp
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      raise IncompatibleTypeError, context: context, value_type: value.class, type: self unless value.is_a?(::String) || value.nil?

      value && ::Regexp.new(value)
    rescue StandardError
      super
    end

    def self.example(_context = nil, options: {})
      ::Regexp.new(/^pattern\d{0,3}$/).to_s
    end

    def self.family
      'string'
    end
  end
end
