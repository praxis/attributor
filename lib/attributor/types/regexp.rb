require_relative '../exceptions'

module Attributor
  class Regexp
    include Type

    def self.native_type
      return ::Regexp
    end

    def self.load(value, context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      unless value.kind_of?(::String) || value.nil?
        raise IncompatibleTypeError,  context: context, value_type: value.class, type: self
      end

      value && ::Regexp.new(value, options[:regexp_opts])
    rescue
      super
    end

    def self.example(context=nil, options:{})
      ::Regexp.new(/^pattern\d{0,3}$/).to_s
    end

    def self.family
      'string'
    end

  end
end
