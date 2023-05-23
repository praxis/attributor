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

    include Attributor
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
      if opts[:reference]
        raise AttributorException, ":reference option can only be used when defining blocks"  unless block_given? 
        if opts[:reference] < Attributor::Collection
          err = ":reference option cannot be a collection. It must be a concrete Struct-like type containing the attribute #{name} you are defining.\n"
          location_file, location_line = block.source_location               
          err += "The place where you are trying to define the attribute is here:\n#{location_file} line #{location_line}\n#{block.source}\n"
          raise AttributorException, err
        end
      end
      target.attributes[name] = define(name, attr_type, **opts, &block)
    end

    def key(name, attr_type = nil, **opts, &block)
      unless name.is_a?(options.fetch(:key_type, Attributor::Object).native_type)
        raise "Invalid key: #{name.inspect}, must be instance of #{options[:key_type].native_type.name}"
      end
      target.keys[name] = define(name, attr_type, **opts, &block)
    end

    def extra(name, attr_type = nil, **opts, &block)
      if attr_type.nil?
        attr_type = Attributor::Hash.of(key: target.key_type, value: target.value_type)
      end
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
    
      if attr_type.nil?
        if block_given?
          final_type, carried_options = resolve_type_for_block(name,  **opts, &block)
        else
          final_type, carried_options = resolve_type_for_no_block(name,  **opts)
        end
      else
        final_type = attr_type
        carried_options = {}
      end

      final_opts = opts.dup
      final_opts.delete(:reference) 
      
      # Possibly add a reference for block definitions (No reference for leaves)
      final_opts.merge!(add_reference_to_block(name, opts)) if block_given?
      final_opts = carried_options.merge(final_opts)
      Attributor::Attribute.new(final_type, final_opts, &block)
    end


    def resolve_type_for_block(name,  **opts)
      resolved_type = nil
      carried_options = {}
      ref = options[:reference]
      if ref && ref.respond_to?(:attributes) && ref.attributes.key?(name)
        type_from_ref = ref.attributes[name]&.type
        resolved_type = type_from_ref < Attributor::Collection ? Attributor::Struct[] : Attributor::Struct
      else
        # Type for attribute with given name could not be determined from reference...or ther is not refrence: defaulting to Struct"
        resolved_type = Attributor::Struct
      end
      [resolved_type, carried_options]
    end

    def resolve_type_for_no_block(name,  **opts)
      resolved_type = nil
      carried_options = {}
      ref = options[:reference]
      if ref && ref.respond_to?(:attributes) && ref.attributes.key?(name)
        resolved_type = ref.attributes[name].type
        carried_options = ref.attributes[name].options
      else
        message = "Type for attribute with name: #{name} could not be determined.\n"
        if ref
          message += "You are defining '#{name}' without a type, and the passed in :reference type (#{ref}) does not have an attribute named '#{name}'.\n" \
        else
          message += "You are defining '#{name}' without a type, and there is no :reference type to infer it from (Did you forget to add the type?).\n" \
        end
        message += "\nIf you are omiting a type thinking that would be inherited from the reference, make sure the right one is passed in," \
          ", which has a #{name} defined, otherwise simply specify the type of the attribute you want.\n"
        raise AttributorException, message
      end
      [resolved_type, carried_options]
    end

    def add_reference_to_block(name, opts)
      base_reference  = options[:reference]
      if opts[:reference] # Direct reference specified in the attribute, just pass it to the block
        {reference: opts[:reference]}
      elsif( base_reference && base_reference.respond_to?(:attributes) && base_reference.attributes.key?(name))
        selected_type = base_reference.attributes[name].type
        selected_type = selected_type.member_attribute.type if selected_type < Attributor::Collection
        {reference: selected_type}
      else
        {}
      end
    end
  end
end
