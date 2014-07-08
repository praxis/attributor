module Attributor
  class Hash
    include Container

    def self.native_type
      return ::Hash
    end

    @key_type = Object
    @value_type = Object

    class <<self
       attr_reader :key_type, :value_type
    end

    # @example Hash.of(key: String, value: Integer)
    def self.of(key: Object, value: Object)
      if key
        resolved_key_type = Attributor.resolve_type(key)
        unless resolved_key_type.ancestors.include?(Attributor::Type)
          raise Attributor::AttributorException.new("Hashes only support key types that are Attributor::Types. Got #{resolved_key_type.name}")
        end
      end

      if value
        resolved_value_type = Attributor.resolve_type(value)
        unless resolved_value_type.ancestors.include?(Attributor::Type)
          raise Attributor::AttributorException.new("Hashes only support value types that are Attributor::Types. Got #{resolved_value_type.name}")
        end
      end
      
      Class.new(self) do
        @key_type = resolved_key_type
        @value_type = resolved_value_type
      end
    end
    
   
        
    def self.example(context=nil, options: {})
      result = ::Hash.new
      # Let's not bother to generate any hash contents if there's absolutely no type defined
      return result if ( key_type == Object && value_type == Object )
      
      size = rand(3) + 1
      context ||= ["#{Hash}-#{rand(10000000)}"]

      size.times do |i|
        example_key = key_type.example(context + ["at(#{i})"])
        subcontext = context + ["at(#{example_key})"]
        result[example_key] = value_type.example(subcontext)
      end

      result
    end

    def self.dump(value, **opts)
      return nil if value.nil?
      return super if (@key_type == Object && @value_type == Object )

      value.each_with_object({}) do |(k,v),hash|
        k = key_type.dump(k,opts) if @key_type
        v = value_type.dump(v,opts) if @value_type
        hash[k] = v
      end
    end

    def self.check_option!(name, definition)
      case name
      when :key_type
        :ok
      when :value_type
        :ok
      else
        :unknown
      end
    end
    
    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT)
      if value.nil?
        return nil
      elsif value.is_a?(::Hash)
        loaded_value = value
      elsif value.is_a?(::String)
        loaded_value = decode_json(value,context)
      else
        raise Attributor::IncompatibleTypeError, context: context, value_type: value.class, type: self 
      end

      return loaded_value if ( key_type == Object && value_type == Object )
      
      loaded_value.each_with_object({}) do| (k, v), obj |
        obj[self.key_type.load(k,context)] = self.value_type.load(v,context)
      end
    end

    # TODO: chance value_type and key_type to be attributes?
    # TODO: add a validate, which simply validates that the incoming keys and values are of the right type. 
    #       Think about the format of the subcontexts to use: let's use .at(key.to_s)
     
  end
end
