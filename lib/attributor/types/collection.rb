# Represents an unordered collection of attributes
#
require_relative '../exceptions'

module Attributor

  class Collection
    include Type

    # @param type [Attributor::Type] optional, defines the type of all collection elements
    # @return anonymous class with specified type of collection elements
    #
    # @example Collection.of(Struct)
    #
    def self.of(type)
      unless type.ancestors.include?(Attributor::Type)
        raise Attributor::AttributorException.new("Collections can only have elements that are Attributor::Types")
      end
      Class.new(self) do
        @element_type = type
      end
    end

    def self.native_type
      return ::Array
    end

    # generates an example Collection
    # @return An Array of native type objects conforming to the specified element_type
    def self.example(options={}, context=nil)
      result = []
      size = rand(10)

      size.times do
        random_type = @element_type || Attributor::BASIC_TYPES.sample
        result << Attributor::Attribute.new(random_type, options).example(context)
      end

      result
    end

    # @param value [Array] currently an array of native types
    def self.validate( value, context, attribute )
      errors = []

      # All elements in the collection Array must be of type Attributor::Type
      value.each_with_index do |element, i|
        errors << "Collection #{context}[#{i}] is not an Attributor::Type" unless element.is_a?(Attributor::Type)
      end

      errors
    end

    def self.validate_options( value, context, attribute )
      errors = []
      errors
    end
  end
end
