require_relative '../exceptions'

module Attributor
  class Regexp
    include Type

    def self.native_type
      ::Regexp
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      unless value.is_a?(::String) || value.nil?
        raise IncompatibleTypeError,  context: context, value_type: value.class, type: self
      end

      value && ::Regexp.new(value)
    rescue
      super
    end

    def self.example(_context = nil, **_options)
      ::Regexp.new(/^pattern\d{0,3}$/).to_s
    end

    def self.family
      'string'
    end
  end
end
