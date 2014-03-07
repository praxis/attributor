module Attributor
  class Hash
    include Container

    def self.native_type
      return ::Hash
    end

    @key_type = Object
    @value_type = Object
    # @example Collection.of(Integer)
    #
    def self.of( key: Object, value: Object )
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
    
    def self.key_type
      @key_type
    end

    def self.value_type
      @value_type 
    end
        
    def self.example(context=nil, options={})
      result = ::Hash.new
      # Let's not bother to generate any hash contents if there's absolutely no type defined
      return result if ( key_type == Object && value_type == Object )
      
      size = rand(3) + 1

      size.times do |i|
        subcontext = "#{context}[#{i}]"
        result[key_type.example(subcontext)] = value_type.example(subcontext)
      end

      result
    end

    def self.check_option!(name, definition)
      case name
      when :key_type
      when :value_type  
      else
        return :unknown
      end
      :ok
    end
    
    def self.load(value)
      if value.nil?
        return nil
      elsif value.is_a?(::Hash)
        loaded_value = value
      elsif value.is_a?(::String)
        loaded_value = decode_json(value)
      else
        raise Attributor::IncompatibleTypeError, value_type: value.class, type: self 
      end

      return loaded_value if ( key_type == Object && value_type == Object )
      
      loaded_value.each_with_object({}) do| (k, v), obj |
        obj[self.key_type.load(k)] = self.value_type.load(v)
      end
    end


  end
end
