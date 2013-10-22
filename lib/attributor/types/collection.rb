# Represents an unordered collection of attributes
#
require_relative '../exceptions'

module Attributor

  class Collection
    include Type

    # @param type [Attributor::Type] optional, defines the type of all collection members
    # @return anonymous class with specified type of collection members
    #
    # @example Collection.of(Integer)
    #
    def self.of(type)
      resolved_type = Attributor.resolve_type(type)
      unless resolved_type.ancestors.include?(Attributor::Type)
        raise Attributor::AttributorException.new("Collections can only have members that are Attributor::Types")
      end
      Class.new(self) do
        @member_type = resolved_type
      end
    end

    def self.native_type
      return ::Array
    end

    def self.member_type
      @member_type ||= Attributor::Object
    end

    def self.member_attribute
      @member_attribute ||= begin
        self.construct(nil,{})
        @member_attribute
      end
    end


    # generates an example Collection
    # @return An Array of native type objects conforming to the specified member_type
    def self.example(options={}, context=nil)
      result = []
      size = rand(10)

      size.times do
        result << self.member_attribute.example(context)
      end

      result
    end

    # Decode JSON string that encapsulates an array
    #
    # @param value [String] JSON string
    # @return [Array] a normal Ruby Array
    #
    def self.decode_json(value)
      raise AttributorException.new("Cannot parse #{value.inspect} as JSON string") unless value.is_a?(::String)
      parsed_value = nil
      begin
        # attempt to parse as JSON
        parsed_value = JSON.parse(value)
      rescue JSON::JSONError => e
        raise AttributorException.new("Could not decode the incoming string as an Array. Is it not JSON? (string was: '#{value}'). Exception: #{e.inspect}")
      end

      if parsed_value.is_a? ::Array
        value = parsed_value
      else
        raise AttributorException.new("JSON-encoded value doesn't appear to be an array (#{parsed_value.inspect})")
      end

      return value
    end

    # The incoming value should be an array here, so the only decoding that we need to do
    # is from the members (if there's an :member_type defined option).
    def self.load(value)
      if value.is_a?(Array)
        loaded_value = value
      elsif value.is_a?(::String)
        loaded_value = decode_json(value)
      else
        raise AttributorException.new("Do not know how to decode an array from a #{value.class.name}")
      end

      # load each member if the member type is an Attributor::Type; may raise AttributorException
      return loaded_value.collect { |member| self.member_attribute.load(member) }
    end


    def self.construct(constructor_block, options)

      member_options = options[:member_options]  || {}

      # create the member_attribute, passing in our member_type and whatever constructor_block is.
      # that in turn will call construct on the type if applicable.
      @member_attribute = Attributor::Attribute.new self.member_type, member_options, &constructor_block

      # overwrite our type with whatever type comes out of the attribute
      @member_type = @member_attribute.type

      return self
    end


    def self.check_option!(name, definition)
      # TODO: support more options like :max_size
      case name
      when :member_options

      else
        :unknown
      end

      :ok
    end

    # @param value [Array] currently an array of native types
    def self.validate( value, context, attribute )
      errors = []

      # All members in the collection Array must be of type Attributor::Type
      value.each_with_index do |member, i|
        errors << "Collection #{context}[#{i}] is not an Attributor::Type" unless member.is_a?(Attributor::Type)
      end

      errors
    end

    def self.validate_options( value, context, attribute )
      errors = []
      errors
    end

  end
end
