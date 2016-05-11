require 'active_support'

require_relative '../exceptions'

module Attributor
  class Polymorphic
    include Type

    class << self
      attr_reader :discriminator
      attr_reader :types
    end

    def self.on(discriminator)
      ::Class.new(self) do
        @discriminator = discriminator
      end
    end

    def self.given(value, type)
      @types[value] = type
    end

    def self.inherited(klass)
      klass.instance_eval do
        @types = {}
      end
    end

    def self.example(context = nil, **values)
      types.values.pick.example(context, **values)
    end

    def self.valid_type?(value)
      self.types.values.include?(value.class)
    end

    def self.constructable?
      true
    end

    def self.native_type
      self
    end

    def self.construct(block, **_options)
      self.instance_eval(&block)
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?

      return value if self.types.values.include?(value.class)

      loaded_value = self.parse(value, context)

      discriminator = loaded_value.fetch(self.discriminator)

      type = self.types.fetch(loaded_value[self.discriminator]) do
        raise "invalid value for discriminator: #{discriminator}"
      end
      type.load(value)
    end

    def self.parse(value, context)
      if value.nil?
        {}
      elsif value.is_a?(Attributor::Hash)
        value.contents
      elsif value.is_a?(::Hash)
        value
      elsif value.is_a?(::String)
        decode_json(value, context)
      elsif value.respond_to?(:to_hash)
        value.to_hash
      else
        raise Attributor::IncompatibleTypeError, context: context, value_type: value.class, type: self
      end
    end
  end
end
