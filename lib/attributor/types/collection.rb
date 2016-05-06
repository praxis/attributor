# Represents an unordered collection of attributes
#

module Attributor
  class Collection < Array
    include Container
    include Dumpable

    # @param type [Attributor::Type] optional, defines the type of all collection members
    # @return anonymous class with specified type of collection members
    #
    # @example Collection.of(Integer)
    #
    def self.of(type)
      resolved_type = Attributor.resolve_type(type)
      unless resolved_type.ancestors.include?(Attributor::Type)
        raise Attributor::AttributorException, 'Collections can only have members that are Attributor::Types'
      end
      ::Class.new(self) do
        @member_type = resolved_type
      end
    end

    @options = {}

    def self.inherited(klass)
      klass.instance_eval do
        @options = {}
      end
    end

    class << self
      attr_reader :options
    end

    def self.native_type
      self
    end

    def self.valid_type?(type)
      type.is_a?(self) || type.is_a?(::Enumerable)
    end

    def self.family
      'array'
    end

    def self.member_type
      @member_type ||= Attributor::Object
    end

    def self.member_attribute
      @member_attribute ||= begin
        construct(nil, {})

        @member_attribute
      end
    end

    # generates an example Collection
    # @return An Array of native type objects conforming to the specified member_type
    def self.example(context = nil, options: {})
      result = []
      size = options[:size] || (rand(3) + 1)
      size = [*size].sample if size.is_a?(Range)

      context ||= ["Collection-#{result.object_id}"]
      context = Array(context)

      # avoid infinite recursion in example generation
      example_depth = context.size
      size = 0 if example_depth > Hash::MAX_EXAMPLE_DEPTH

      size.times do |i|
        subcontext = context + ["at(#{i})"]
        result << member_attribute.example(subcontext)
      end

      new(result)
    end

    # The incoming value should be array-like here, so the only decoding that we need to do
    # is from the members (if there's an :member_type defined option).
    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **_options)
      return nil if value.nil?
      if value.is_a?(Enumerable)
        loaded_value = value
      elsif value.is_a?(::String)
        loaded_value = decode_string(value, context)
      elsif value.respond_to?(:to_a)
        loaded_value = value.to_a
      else
        raise Attributor::IncompatibleTypeError, context: context, value_type: value.class, type: self
      end

      new(loaded_value.collect { |member| member_attribute.load(member, context) })
    end

    def self.decode_string(value, context)
      decode_json(value, context)
    end

    def self.dump(values, **opts)
      return nil if values.nil?
      values.collect { |value| member_attribute.dump(value, opts) }
    end

    def self.describe(shallow = false, example: nil)
      hash = super(shallow)
      hash[:options] = {} unless hash[:options]
      member_example = example.first if example
      hash[:member_attribute] = member_attribute.describe(true, example: member_example)
      hash
    end

    def self.constructable?
      true
    end

    def self.construct(constructor_block, options)
      member_options = (options[:member_options] || {}).clone
      if options.key?(:reference) && !member_options.key?(:reference)
        member_options[:reference] = options[:reference]
      end

      # create the member_attribute, passing in our member_type and whatever constructor_block is.
      # that in turn will call construct on the type if applicable.
      @member_attribute = Attributor::Attribute.new member_type, member_options, &constructor_block

      # overwrite our type with whatever type comes out of the attribute
      @member_type = @member_attribute.type

      self
    end

    def self.check_option!(name, _definition)
      # TODO: support more options like :max_size
      case name
      when :reference
      when :member_options
      else
        return :unknown
      end

      :ok
    end

    # @param object [Collection] Collection instance to validate.
    def self.validate(object, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
      context = [context] if context.is_a? ::String

      unless object.is_a?(self)
        raise ArgumentError, "#{name} can not validate object of type #{object.class.name} for #{Attributor.humanize_context(context)}."
      end

      object.validate(context)
    end

    def self.validate_options(_value, _context, _attribute)
      errors = []
      errors
    end

    def validate(context = Attributor::DEFAULT_ROOT_CONTEXT)
      each_with_index.collect do |value, i|
        subcontext = context + ["at(#{i})"]
        self.class.member_attribute.validate(value, subcontext)
      end.flatten.compact
    end

    def dump(**opts)
      collect { |value| self.class.member_attribute.dump(value, opts) }
    end
  end
end
