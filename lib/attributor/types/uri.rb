# Represents a href type.
require 'uri'

module Attributor
  class URI
    include Attributor::Type

    def self.family
      String.family
    end

    def self.valid_type?(value)
      case value
      when ::String, ::URI::Generic
        true
      else
        false
      end
    end

    def self.native_type
      ::URI::Generic
    end

    def self.example(_context = nil, **_options)
      URI(Randgen.uri)
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?
      case value
      when native_type
        value
      when ::String
        URI(value)
      else
        raise CoercionError, context: context, from: value.class, to: self, value: value
      end
    end

    def self.dump(value, **_opts)
      value.to_s
    end

    def self.validate(value, context = Attributor::DEFAULT_ROOT_CONTEXT, attribute)
      errors = []

      if attribute && (definition = attribute.options[:path])
        unless value.path =~ attribute.options[:path]
          errors << "#{Attributor.humanize_context(context)} value (#{value}) does not match path (#{definition.inspect})"
        end
      end
      errors
    end

    def self.check_option!(name, definition)
      case name
      when :path
        unless definition.is_a? ::Regexp
          raise AttributorException, "Value for option :path is not a Regexp object. Got (#{definition.inspect})"
        end
        :ok
      else
        :unknown
      end
    end
  end
end

class Randgen
  def self.uri
    "http://example.com/#{word}/#{rand(10**9)}"
  end
end
