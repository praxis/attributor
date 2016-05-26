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

    def self.construct(constructor_block, **_options)
      return self if constructor_block.nil?

      self.instance_eval(&constructor_block)
      self
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?

      return value if self.types.values.include?(value.class)

      parsed_value = self.parse(value, context)

      discriminator_value = discriminator_value_for(parsed_value)

      type = self.types.fetch(discriminator_value) do
        raise LoadError, "invalid value for discriminator: #{discriminator_value}"
      end
      type.load(parsed_value)
    end

    def self.discriminator_value_for(parsed_value)
      return parsed_value[self.discriminator] if parsed_value.key?(self.discriminator)

      value = case self.discriminator
      when ::String
        parsed_value[self.discriminator.to_sym]
      when ::Symbol
        parsed_value[self.discriminator.to_s]
      end

      return value if value

      raise LoadError, "can't find key #{self.discriminator.inspect} in #{parsed_value.inspect}"
    end

    def self.dump(value, **opts)
      if (loaded = load(value))
        loaded.dump(**opts)
      end
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

    def self.describe(shallow = false, example: nil)
      super.merge(
        discriminator: self.discriminator,
        types: self.describe_types
      )
    end

    def self.describe_types
      self.types.each_with_object({}) do |(key, value), description|
        description[key] = { type: value.describe(true) }
      end
    end
  end
end
