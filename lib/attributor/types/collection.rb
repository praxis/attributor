# Represents an unordered collection of attributes
#
require_relative '../exceptions'

module Attributor

  class Collection
    include Type

    # @param type [Attributor::Type] optional, defines the type of all collection members
    # @return anonymous class with specified type of collection members
    #
    # @example Collection.of(Struct)
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
      @member_type
    end

    def self.member_attribute
      @member_attribute
    end
    
    # generates an example Collection
    # @return An Array of native type objects conforming to the specified member_type
    def self.example(options={}, context=nil)
      result = []
      size = rand(10)

      size.times do
        random_type = @member_type || Attributor::BASIC_TYPES.sample
        result << Attributor::Attribute.new(random_type, options).example(context)
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
        raise AttributorException.new("Could not decode the incoming string as an Array. Is it not JSON? (string was: #{value}). Exception: #{e.inspect}")
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

      return loaded_value if (@member_type.nil? || loaded_value.empty?)

      # load each member if the member type is an Attributor::Type; may raise AttributorException
      another_array = []
      loaded_value.each_with_index do |member, i|
        loaded_member = @member_type.load(member)
        another_array << loaded_member
      end

      return another_array
    end

    def self.construct(constructor_block, options)
      # Actually need to construct the member type so that we can
      # compile the block and define the member type.

      if @member_type.respond_to?(:construct)
        @member_type = @member_type.construct(constructor_block, options) 
      end  
      
      @member_attribute = Attributor::Attribute.new member_type, options[:member_options], &constructor_block
      
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

#    def self.respond_to?(method_name)
#      if method_name == :construct
#        return @member_type.respond_to?(:construct)
#      end
#
#      super
#    end
  end
end
