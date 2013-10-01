# Represents a plain old boolean type. TBD: can be nil?
#
require_relative '../exceptions'

module Attributor

  class Boolean
    include Type

    def self.valid_type?(value)
      value == true || value == false
    end

    def self.example(options={}, context=nil)
      [true, false].sample
    end

    def self.load(value)
      raise AttributorException.new("Cannot coerce '#{value.inspect}' into Boolean type") if value.is_a?(Float)
      return false if [ false, 'false', 'FALSE', '0', 0, 'f', 'F' ].include?(value)
      return true if [ true, 'true', 'TRUE', '1', 1, 't', 'T' ].include?(value)
      raise AttributorException.new("Cannot coerce '#{value.inspect}' into Boolean type")
    end
  end
end

