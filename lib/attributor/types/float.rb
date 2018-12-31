# frozen_string_literal: true

# Float objects represent inexact real numbers using the native architecture's double-precision floating point representation.
# See: http://ruby-doc.org/core-2.1.0/Float.html

module Attributor
  class Float
    include Type

    def self.native_type
      ::Float
    end

    def self.example(_context = nil, options: {})
      min = options[:min].to_f || 0.0
      max = options[:max].to_f || Math.PI

      rand * (max - min) + min
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      Float(value)
    rescue TypeError
      super
    end

    def self.family
      'numeric'
    end
  end
end
