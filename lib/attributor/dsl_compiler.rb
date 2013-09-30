#Container of options and structure definition
module Attributor
  class DSLCompiler

    attr_accessor :attributes, :options

    def initialize(options={})
      @options = options
      @attributes={}
    end

    def parse(&block)
      self.instance_eval(&block) if block
      # OPTIMIZE: clear out the saved block?
      return self
    end



    def attribute(name, type_or_options=nil, opts={}, &block)
      raise AttributorException.new("Attribute #{name} already defined") if attributes.has_key? name

      if type_or_options.kind_of? ::Class
        if block_given?
          if reference = self.options[:reference]
            if inherited_attribute = reference.definition.attributes[name]
              opts[:reference] = inherited_attribute.type
            end
          end
        end
        return attributes[name] = Attributor::Attribute.new(type_or_options, opts, &block)
      end

      if reference = self.options[:reference]
        inherited_attribute = reference.definition.attributes.fetch(name) do |k|
          raise "can not inherit attribute with name #{k} from reference type #{reference}"
        end
        type = inherited_attribute.type

        case type_or_options
        when ::Hash
          opts = inherited_attribute.options.merge(type_or_options)
        when nil
          opts = inherited_attribute.options.merge(opts || {})
        else
          raise "unknown value for type_or_options: #{type_or_options.inspect}"
        end
      elsif block_given?
        type = Attributor::Struct
        opts = type_or_options || opts
      else
        raise 'type not specified' # (really, and no reference was given, or block to assume Struct for)
      end

      attributes[name] = Attributor::Attribute.new(type, opts, &block)
    end




    def old_attribute(name, type_or_options=nil, opts={}, &block)
      raise "Attribute #{name} already defined" if attributes.has_key? name

      if type_or_options.kind_of? ::Class
        return attributes[name] = Attributor::Attribute.new(type_or_options, opts, &block)
      end



      inherited_attribute = self.inherit_attribute(name)
      type = inherited_attribute.type

      case type_or_options
      when ::Hash
        opts = inherited_attribute.options.merge(type_or_options)
      when nil
        opts = inherited_attribute.options.merge(opts || {})
      else
        raise "unknown value for type_or_options: #{type_or_options.inspect}"
      end


      #opts[:inherit_from] = @inherit_from[name] if @inherit_from
      # FIXME: test this
      if type < Attributor::Model
        #if type < Attributor::Struct
        opts[:reference] = type
        type = Attributor::Struct
        #elsif type < Attributor::Collection
        #  opts[:reference] = type
        #  type = Attributor::Collection.of(Struct)
      end

      attributes[name] = Attributor::Attribute.new(type, opts, &block)
    end

    alias_method :param, :attribute


    # def private_decode_args_for_attribute( incoming_type, incoming_opts)
    #   if( incoming_type == nil )
    #     type = nil
    #     opts = incoming_opts.dup
    #   elsif( incoming_type.is_a?(::Hash) )
    #     type = nil
    #     opts = incoming_type.dup
    #   else
    #     type = incoming_type
    #     opts = incoming_opts.dup
    #   end
    #   { :type => type, :opts=>opts }
    # end

    # def describe_attributes
    #   sub_definition = {}
    #   attributes.each do |name, object|
    #     sub_definition[name] = object.describe
    #   end
    #   sub_definition
    # end

  end
end
