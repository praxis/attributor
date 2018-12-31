# frozen_string_literal: true

# Abstract type for the 'temporal' family

module Attributor
  class Temporal
    include Type

    def self.native_type
      raise NotImplementedError
    end

    def self.family
      'temporal'
    end

    def self.dump(value, **_opts)
      value&.iso8601
    end
  end
end
