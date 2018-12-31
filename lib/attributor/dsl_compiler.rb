# frozen_string_literal: true

# Container of options and structure definition
module Attributor
  # RULES FOR ATTRIBUTES
  #   The type of an attribute is:
  #     the specified type
  #     inferred from a reference type.
  #       it should always end up being an anonymous type, otherwise the Model class will explode
  #     Struct if a block is given

  #   The reference option for an attribute is passed if a block is given

  class DSLCompiler
    attr_accessor :options, :target

    def initialize(target, **options)
      @target = target
      @options = options
    end

    def parse(*blocks)
      blocks.push(Proc.new) if block_given?
      blocks.each { |block| instance_eval(&block) }
      self
    end

    def attributes
      if target.respond_to?(:attributes)
        target.attributes
      else
        target.keys
      end
    end

    def attribute(name, attr_type = nil, **opts, &block)
      raise AttributorException, "Attribute names must be symbols, got: #{name.inspect}" unless name.is_a? ::Symbol

      target.attributes[name] = define(name, attr_type, **opts, &block)
    end

    def key(name, attr_type = nil, **opts, &block)
      raise "Invalid key: #{name.inspect}, must be instance of #{options[:key_type].native_type.name}" unless name.is_a?(options.fetch(:key_type, Attributor::Object).native_type)

      target.keys[name] = define(name, attr_type, **opts, &block)
    end

    def extra(name, attr_type = nil, **opts, &block)
      attr_type = Attributor::Hash.of(key: target.key_type, value: target.value_type) if attr_type.nil?
      target.extra_keys = name
      target.options[:allow_extra] = true
      opts[:default] ||= {}
      attr_type.options[:allow_extra] = true
      key(name, attr_type, **opts, &block)
    end

    # Creates an Attributor:Attribute with given definition.
    #
    # @overload define(name, type, opts, &block)
    #   With an explicit type.
    #   @param [symbol] name describe name param
    #   @param [Attributor::Type] type describe type param
    #   @param [Hash] opts describe opts param
    #   @param [Block] block describe block param
    #   @example
    #     attribute :email, String, example: Randgen.email
    # @overload define(name, opts, &block)
    #   Assume a type of Attributor::Struct
    #   @param [symbol] name describe name param
    #   @param [Hash] opts describe opts param
    #   @param [Block] block describe block param
    #   @example
    #     attribute :address do
    #       attribute :number, String
    #       attribute :street, String
    #       attribute :city, String
    #       attribute :state, String
    #     end
    # @api semiprivate
    def define(name, attr_type = nil, **opts, &block)
      example_given = opts.key? :example

      # add to existing attribute if present
      if (existing_attribute = attributes[name])
        if existing_attribute.attributes
          existing_attribute.type.attributes(&block)
          return existing_attribute
        end
      end

      # determine inherited type (giving preference to the direct attribute options)
      inherited_type = opts[:reference]
      unless inherited_type
        reference = options[:reference]
        if reference&.respond_to?(:attributes) && reference.attributes.key?(name)
          inherited_attribute = reference.attributes[name]
          opts = inherited_attribute.options.merge(opts) unless attr_type
          inherited_type = inherited_attribute.type
          opts[:reference] = inherited_type if block_given?
        end
      end

      # determine attribute type to use
      if attr_type.nil?
        if block_given?
          # Don't inherit explicit examples if we've redefined the structure
          # (but preserve the direct example if given here)
          opts.delete :example unless example_given
          attr_type = if inherited_type && inherited_type < Attributor::Collection
                        # override the reference to be the member_attribute's type for collections
                        opts[:reference] = inherited_type.member_attribute.type
                        Attributor::Collection.of(Struct)
                      else
                        Attributor::Struct
                      end
        elsif inherited_type
          attr_type = inherited_type
        else
          raise AttributorException, "type for attribute with name: #{name} could not be determined"
        end
      end

      Attributor::Attribute.new(attr_type, opts, &block)
    end
  end
end
