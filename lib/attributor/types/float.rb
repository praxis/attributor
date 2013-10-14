# Float objects represent inexact real numbers using the native architecture's double-precision floating point representation.
# See: http://ruby-doc.org/core-1.9.3/Float.html
#
module Attributor

  class Float
    include Type

    def self.native_type
      return ::Float
    end

    def self.example(options={},context=nil)
      min = options[:min].to_f || 0.0
      max = options[:max].to_f || Math.PI

      rand * (max-min) + min
    end

    def self.load(value)
      if value.is_a?(::String)
        return Float(value)
      end

      if value.is_a?(::Integer)
        return Float(value)
      end

      super
    end

  end
end
