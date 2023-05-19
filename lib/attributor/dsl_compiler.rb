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
      raise AttributorException, ":reference option can only be used when defining blocks" if opts[:reference] && !block_given? 
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
      
      res = origdefine(name, attr_type, **opts, &block)
      # puts "DEFINED: #{name} (t: #{attr_type}) as #{res[0]} and options:\n#{res[1]}"
      Attributor::Attribute.new(res[0], res[1], &block)
    end

    def good_explanation_about_redefining_already_defined_types(name, ref, type_from_ref, &block)
      existing_type_name = type_from_ref < Attributor::Collection ? "Collection.of(#{type_from_ref.member_attribute.type})" : type_from_ref.to_s
      location_file, location_line = block.source_location
      message = "Invalid redefinition of attributes for an already existing type:\n"
      message += "Existing type Type #{existing_type_name} cannot be further redefined with the block you are providing.\n"
      message += "You are getting this because you are not specifying an explicit type for your '#{name}' attribute, and therefore"
      message += "the framework is trying to inherit the type from the passed :reference option in the enclosing block. This :reference "
      message += "is pointing to type: #{ref}, which also has an attribute named '#{name}' with type #{existing_type_name}, that matches"
      message += "the name of the attribute you are trying to define in here:\n#{location_file} line #{location_line}\n#{block.source}\n"
      message += "It is likely that you either want to explictly set the type to a Struct (or Collection.of(Struct)) and redefine that in your block"
      message += "or perhaps you want to 'refine/change' the attributes of #{ref} within your block, in which case what you should do is to"
      message += "explicitly set the type to a Struct (or Collection.of(Struct)) and then use the :reference option to point to #{ref}.\n"
      raise message
    end
    def resolveTypeForBlock(name,  **opts, &block)
      resolved_type = nil
      carried_options = {}
      ref = options[:reference]
      if ref
        if ref.respond_to?(:attributes) && ref.attributes.key?(name)
          type_from_ref = ref.attributes[name]&.type

          resolved_type = type_from_ref < Attributor::Collection ? Attributor::Struct[] : Attributor::Struct

          # unless type_from_ref == Attributor::Struct || type_from_ref == Attributor::Collection.of(Attributor::Struct)
          #   good_explanation_about_redefining_already_defined_types(name, ref, type_from_ref, &block)
          # end
          # resolved_type = type_from_ref # Return the raw, and anonymous type Struct or Attributor::Collection.of(Attributor::Struct)

          # TODO: We could default to Struct[] if we see the reference is a Collection ...
          # resolved_type = Attributor::Struct
          #carried_options = ref.attributes[name].options # Somehow bring any options from the type?
        else
          puts "WARNING: Type for attribute with name: #{name} could not be determined from reference: #{ref}...defaulting to Struct"
          resolved_type = Attributor::Struct
          
          # message = "Type for attribute with name: #{name} could not be determined.\n"
          # if ref
          #   message += "You are defining '#{name}' without a type, and the passed in :reference type (#{ref}) does not have an attribute named '#{name}'.\n" \
          # else
          #   message += "You are defining '#{name}' without a type, and there is no :reference type to infer it from (Did you forget to add the type?).\n" \
          # end
          # location_file, location_line = block.source_location
          # message += "\nIf you are omiting a type, thinking that would be inherited from the reference, make sure the right one is passed in," \
          #   ",add the missing attribute to the reference type or simply add the right missing type in the attribute definition otherwise.\n"
          #   "If you are omiting it to imply it is a Struct, please explicitly add it in the attribute definition (or add the right missing type otherwise)\n"
          # message += "This is the definition block where the issue was found:\n#{location_file} line #{location_line}\n#{block.source}"
          # require 'pry'
          # binding.pry
          # raise AttributorException, message
        end
      else
        resolved_type = Attributor::Struct
      end
      # TODO: We could also default to Struct if there is a reference, but does not have the attribute ....
      [resolved_type, carried_options]
    end

    def resolveTypeForNoBlock(name,  **opts)
      resolved_type = nil
      carried_options = {}
      ref = options[:reference]
      if ref && ref.respond_to?(:attributes) && ref.attributes.key?(name)
        resolved_type = ref.attributes[name].type
        carried_options = ref.attributes[name].options
      else
        # require 'pry'
        # binding.pry
        message = "Type for attribute with name: #{name} could not be determined.\n"
          # if ref
          #   message += "You are defining '#{name}' without a type, and the passed in :reference type (#{ref}) does not have an attribute named '#{name}'.\n" \
          # else
          #   message += "You are defining '#{name}' without a type, and there is no :reference type to infer it from (Did you forget to add the type?).\n" \
          # end
          # location_file, location_line = block.source_location
          # message += "\nIf you are omiting a type, thinking that would be inherited from the reference, make sure the right one is passed in," \
          #   ",add the missing attribute to the reference type or simply add the right missing type in the attribute definition otherwise.\n"
          #   "If you are omiting it to imply it is a Struct, please explicitly add it in the attribute definition (or add the right missing type otherwise)\n"
          # message += "This is the definition block where the issue was found:\n#{location_file} line #{location_line}\n#{block.source}"
        raise AttributorException, message
      end
      [resolved_type, carried_options]
    end

    def addReferenceToBlock(name, opts)
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

    def origdefine(name, attr_type = nil, **opts, &block)
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
          # if(name == :neighbors)
          #   require 'pry'
          #   binding.pry
          #   require 'pry'
          #   binding.pry
          # end
          final_type, carried_options = resolveTypeForBlock(name,  **opts, &block)
        else
          final_type, carried_options = resolveTypeForNoBlock(name,  **opts)
        end
      else
        final_type = attr_type
        carried_options = {}
      end

      
      final_opts = opts.dup
      final_opts.delete(:reference) 
      if block_given?
        final_opts.merge!(addReferenceToBlock(name, opts))
      else
        # No reference for leaves
      end
      # TODO: Need to percolate incoming ops as well...
      final_opts = carried_options.merge(final_opts)

      # puts "DEFINING: #{name} with type #{attr_type} and opts #{opts} (DSL Opts: #{options})"
      # puts "-----   : resolved to: #{final_type} and opts #{final_opts}"

      return [final_type, final_opts]
      ##############################
      # determine inherited type (giving preference to the direct attribute options)
      type_from_ref = opts[:reference]
      unless type_from_ref
        reference = options[:reference]
        if reference && reference.respond_to?(:attributes) && reference.attributes.key?(name)
          inherited_attribute = reference.attributes[name]
          
          if block_given?
            type_from_ref = inherited_attribute.type
            opts[:reference] = type_from_ref # We pass it down in case, but the block might completely redefine it
          else
            opts = inherited_attribute.options.merge(opts) unless attr_type #?? why unless?            
          end
        end
      end

      # determine attribute type to use
      if attr_type.nil?
        if block_given?
          # Don't inherit explicit examples if we've redefined the structure 
          # (but preserve the direct example if given here)
          opts.delete :example unless  example_given
          attr_type = if type_from_ref && type_from_ref < Attributor::Collection
                        # override the reference to be the member_attribute's type for collections
                        opts[:reference] = type_from_ref.member_attribute.type
                        Attributor::Collection.of(Struct)
                      else
                        Attributor::Struct
                      end
        elsif type_from_ref
          attr_type = type_from_ref
        else
          require 'pry'
          binding.pry
          raise AttributorException, "type for attribute with name: #{name} could not be determined!"
        end
      end
      [attr_type, opts]
    end
    def newdefine(name,  attr_type = nil, **opts, &block)
      ref = opts[:reference] || options[:reference]
      # puts "DEFINING: #{name} with type #{attr_type} and opts #{opts} (DSL Opts: #{options})=> ref: #{ref}"

      if attr_type.nil?
        if block_given?
          if ref
            if ref.respond_to?(:attributes) && ref.attributes.key?(name)
              inherited_attribute = ref.attributes[name]
              inherited_type = inherited_attribute.type
              final_type = inherited_type < Attributor::Collection ?  Attributor::Collection.of(Attributor::Struct) : Attributor::Struct
              if inherited_type < Attributor::Collection
                opts = inherited_attribute.options.merge(opts)
                # override the reference to be the member_attribute's type for collections
                inherited_type = inherited_type.member_attribute.type
              elsif inherited_type < Attributor::Model # Allow it to be a model, not just a struct
                opts = inherited_attribute.options.merge(opts) # Merge all options if reference is a Struct
              end
              opts[:reference] = inherited_type  if inherited_type # Pass reference if any
            end
          else
            # No type and no reference, it's a 'blank' Struct by default (since there's a block given), best we can do
            # Note: cannot try to define a Collection of Struct here, since we don't know the type of the collection
            final_type = Attributor::Struct
          end
          # The reference is for the block attributes...if we don't have one (and don't have a type, we cannot really guess it)
          # if ref.nil?
          #   if ref && ref.respond_to?(:attributes) && ref.attributes.key?(name)
          #     inherited_attribute = ref.attributes[name]
          #     inherited_type = inherited_attribute.type
          #     final_type = inherited_type < Attributor::Collection ?  Attributor::Collection.of(Attributor::Struct) : Attributor::Struct
          #     if inherited_type && inherited_type < Attributor::Collection
          #       opts = inherited_attribute.options.merge(opts)
          #       # override the reference to be the member_attribute's type for collections
          #       inherited_type = inherited_type.member_attribute.type
          #     elsif inherited_type < Attributor::Model # Allow it to be a model, not just a struct
          #       opts = inherited_attribute.options.merge(opts) # Merge all options if reference is a Struct
          #     end
          #     opts[:reference] = inherited_type  if inherited_type # Pass reference if any
          #   else
          #     opts[:reference] = ref # Could be rewriting the already existing one in ops, or use the one in options...
          #   end
          # end
          opts[:reference] = ref # Could be rewriting the already existing one in ops, or use the one in options...
          # If there's no type and no reference, it's a Struct by default (since there's a block given)
          final_type = final_type || Attributor::Struct
        else
          # Do not pass reference even if there's one
          if ref
            resolved_ref =  ref < Attributor::Collection ? ref.member_attribute.type : ref
            if resolved_ref.respond_to?(:attributes) && resolved_ref.attributes.key?(name)
              inherited_attribute = resolved_ref.attributes[name]
              final_type = inherited_attribute.type # Find the ref type
              opts = inherited_attribute.options.merge(opts) # Merge all options
            end
          end
        end
      else
        if block_given?
          # if ref && ref.respond_to?(:attributes) && ref.attributes.key?(name)
          #   inherited_attribute = ref.attributes[name]
          #   inherited_type = inherited_attribute.type
          #   if inherited_type && inherited_type < Attributor::Collection
          #     # override the reference to be the member_attribute's type for collections
          #     opts[:reference] = inherited_type.member_attribute.type
          #   else
          #     opts[:reference] = inherited_type
          #   end  
          #   opts = inherited_attribute.options.merge(opts) # Merge all options
          # end
          # NEED TO PASS A REFERENCE IF THERE's A TYPE? or should be look it up?
          final_type = attr_type
        else
          if ref && ref.respond_to?(:attributes) && ref.attributes.key?(name)
            inherited_attribute = ref.attributes[name]
            opts = inherited_attribute.options.merge(opts) # Merge all options
          end
          final_type = attr_type
        end
      end
      # # determine inherited type (giving preference to the direct attribute options)
      # inherited_type = opts[:reference]
      # unless inherited_type
      #   reference = options[:reference]
      #   if reference && reference.respond_to?(:attributes) && reference.attributes.key?(name)
      #     inherited_attribute = reference.attributes[name]
      #     unless attr_type
      #       inherited_type = inherited_attribute.type
      #       opts[:reference] = inherited_type if block_given?
  
      #       if inherited_type < Attributor::Collection || inherited_type < Attributor::Hash
      #         opts = inherited_attribute.options.merge(opts) 
      #       end
      #     end
      #   end
      # end

      # # determine attribute type to use
      # if attr_type.nil?
      #   if block_given?
      #     # Don't inherit explicit examples if we've redefined the structure 
      #     # (but preserve the direct example if given here)
      #     opts.delete :example unless  example_given
      #     attr_type = if inherited_type && inherited_type < Attributor::Collection
      #                   # override the reference to be the member_attribute's type for collections
      #                   opts[:reference] = inherited_type.member_attribute.type
      #                   Attributor::Collection.of(Struct)
      #                 else
      #                   Attributor::Struct
      #                 end
      #   elsif inherited_type
      #     attr_type = inherited_type
      #   else
      #     raise AttributorException, "type for attribute with name: #{name} could not be determined"
      #   end
      # end
        
      raise AttributorException, "type for attribute with name: #{name} could not be determined" unless final_type

      [final_type, opts]
    end
  end
end
