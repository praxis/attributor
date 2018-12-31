# frozen_string_literal: true

begin
  require 'parslet'
rescue LoadError
  warn "Attributor::FieldSelector requires the 'parslet' gem, which can not be found. " \
       "Please make sure it's in your Gemfile or installed in your system."
end

module Attributor
  class FieldSelector
    require 'attributor/extras/field_selector/parser'
    require 'attributor/extras/field_selector/transformer'

    include Attributor::Type

    def self.native_type
      ::Hash
    end

    def self.example(_context = nil, options: {})
      3.times.each_with_object([]) do |_i, array|
        array << /\w{5,8}/.gen
      end.join(',')
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?
      return value if valid_type? value
      return {} if value.empty?

      parsed = Parser.new.parse(value)
      Transformer.new.apply(parsed)
    rescue StandardError
      raise CoercionError, context: context, from: value.class, to: self, value: value
    end

    def self.validate(_value, _context = nil, _attribute)
      [].freeze
    end

    def self.valid_type?(value)
      return true if value.is_a?(native_type) || value.is_a?(self.class)
    end
  end
end
