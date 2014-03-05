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
    def self.example(context=nil, options={})
      result = []
      size = rand(10) + 1

      size.times do |i|
        subcontext = "#{context}[#{i}]"
        result << self.member_attribute.example(subcontext)
      end

      result
    end


    # The incoming value should be an array here, so the only decoding that we need to do
    # is from the members (if there's an :member_type defined option).
    def self.load(value)
      if value.nil?
        return nil
      elsif value.is_a?(Enumerable)
        loaded_value = value
      elsif value.is_a?(::String)
        loaded_value = decode_json(value)
      else
        raise Attributor::IncompatibleTypeError, value_type: value.class, type: self 
      end

      return loaded_value.collect { |member| self.member_attribute.load(member) }
    end


    def self.dump(values, opts=nil)
      values.collect { |value| member_attribute.dump(value,opts) }
    end

    def self.describe(shallow=false)
      #puts "Collection: #{self.type}"      
      hash = super(shallow)
      hash[:member_attribute] = self.member_attribute.describe
      hash
    end

    def self.construct(constructor_block, options)

      member_options =  (options[:member_options]  || {} ).clone
      if options.has_key?(:reference) && !member_options.has_key?(:reference)
        member_options[:reference] = options[:reference]
      end
      
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
      when :reference
      when :member_options
      else
        return :unknown
      end

      :ok
    end

    # @param values [Array] Array of values to validate
    def self.validate(values, context, attribute)
      values.each_with_index.collect do |value, i|
        subcontext = "#{context}[#{i}]"
        self.member_attribute.validate(value, subcontext)
      end.flatten.compact
    end

    def self.validate_options( value, context, attribute )
      errors = []
      errors
    end

  end
end
