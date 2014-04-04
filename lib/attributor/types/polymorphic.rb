module Attributor
  class Polymorphic 
#    include Attributor::Type #??? think this through...
    
    attr_reader :discriminator_name, :discriminator_type
    
    def self.on(discriminator_field)
      #      raise "The name of field defining the type is required for Polymorphic types" unless discriminator_field
      if discriminator_field.is_a? ::Hash
        field_name, field_type = discriminator_field.first
      else
        field_name = discriminator_field
      end
      Class.new(self) do
        @discriminator_name = field_name
        @discriminator_type = field_type if field_type
      end
    end
    
    def self.discriminator_name
      @discriminator_name ||= :type
    end
    def self.discriminator_type
      @discriminator_type ||= ::String
    end

    
    def self.polymorphic_attributes
      @polymorphic_attributes ||= {}
    end
    
    def self.valid_type?(value)
      polymorphic_attributes.values.any? do |attribute|
        attribute.type.valid_type?(value)
      end
    end
    
    def self.construct(constructor_block, options)
      #TODO...think about inheriting options for when the 'given' block gets executed (so attributes get extra options...)
      
      # Static classed types deriving from a Polymorphic type could be assigned to an attribute as such (i.e. with no further block)
      self.instance_eval(&constructor_block) if constructor_block
    #  member_options =  (options[:member_options]  || {} ).clone
    #  if options.has_key?(:reference) && !member_options.has_key?(:reference)
    #    member_options[:reference] = options[:reference]
    #  end
      
      # create the member_attribute, passing in our member_type and whatever constructor_block is.
      # that in turn will call construct on the type if applicable.
     # @member_attribute = Attributor::Attribute.new self.member_type, member_options, &constructor_block
     #
     # # overwrite our type with whatever type comes out of the attribute
     # @member_type = @member_attribute.type
     
     return self
    end
    
    def self.given( discriminator_value, type, opts={}, &proc)


      # TODO: Think about this...we're converting symbols to strings here if the type is string...so we're always having the native type underneath...
      discriminator_value = discriminator_value.to_s if discriminator_type == ::String && discriminator_value.is_a?(::Symbol)
      raise "WARNING: trying to define a polymorphic mapping for a type name that has already been defined" if polymorphic_attributes[discriminator_value]
      
      raise "Type for #{discriminator_value} is (#{discriminator_value.class}) and does not match the defined type (#{discriminator_type}) in this polymorphic description" unless discriminator_value.is_a?(discriminator_type)
      
      polymorphic_attributes[discriminator_value]= Attributor::Attribute.new type, opts, &proc
    end
    
    def self.load(value)
      matching_attr = self._select_matching_attribute(value)
      return matching_attr.load( value )
    end

    def self.validate(value, context, attribute)
      matching_attr = self._select_matching_attribute(value)

      matching_attr.validate(value, context)
    end

    # Extract the discriminator value
    def self._select_matching_attribute(value)

      discriminator_value = if value.kind_of? ::Hash # Special case when it is a hash that comes in (let's reach in directly)
        value[discriminator_name] || value[discriminator_name.to_sym] 
      else #Otherwise, let's simply load the value (assuming it has to be a model/struct-type)
        simple_load = Attributor::Model.load(value) 
        simple_load.send(discriminator_name)
      end
      
      # FIXME: if we make sure the values we store in the 'given' for String-types, then we should always convert back to symbols
      discriminator_value = discriminator_value.to_sym if ( discriminator_type == String && !discriminator_value.is_a?(Symbol) )
      selected = polymorphic_attributes[discriminator_value]
      unless selected
        raise Attributor::LoadError, "Invalid polymorphic type value: '#{discriminator_value}'. Allowed values for '#{discriminator_name}': [#{polymorphic_attributes.keys.join(',')}]" 
      end
      selected
    end
    
    

    def self.dump(value, opts=nil)
      #TODO: validate inputs nils..etc
      matching_attr = polymorphic_attributes[value.send(discriminator_name)]
      matching_attr.dump(value,opts)
    end

    def self.describe(shallow=false)
      raise "TODO!"
    end
    
    def self.example(context=nil, options: {})
      # Pick on the of the attributes and generate an example
      key_pick = polymorphic_attributes.keys[ rand(polymorphic_attributes.size) ]
      polymorphic_attributes[key_pick].example(context, options)
    end

    def self.check_option!(name, definition)
      # TODO: build in any options it might take
      :unknown
    end
    def self.validate_options( value, context, attribute )
      # TODO: Anythng to do here?
      errors = []
      errors
    end
  end
end