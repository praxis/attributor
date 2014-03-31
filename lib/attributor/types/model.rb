module Attributor
  class Model
    include Attributor::Type
    MAX_EXAMPLE_DEPTH = 5
    CIRCULAR_REFERENCE_MARKER = '...'.freeze

    # FIXME: this is not the way to fix this. Really we should add finalize! to Models.
    undef :timeout

    # Define accessors for attribute of given name.
    #
    # @param name [::Symbol] attribute name
    #
    def self.define_accessors(name)
      name = name.to_sym
      self.define_reader(name)
      self.define_writer(name)
    end


    def self.define_reader(name)
      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
          return @attributes[:#{name}] if @attributes.has_key?(:#{name})

          @attributes[:#{name}] = begin
            if (proc = @lazy_attributes.delete :#{name})
              if proc.arity > 0
                proc.call(self)
              else
                proc.call
              end
            end
          end
        end
      RUBY
    end


    def self.define_writer(name)
      attribute = self.attributes[name]
      # note: paradoxically, using define_method ends up being faster for the writer
      #       attribute is captured by the block, saving us from having to retrieve it from
      #       the class's attributes hash on each write.
      module_eval do
        define_method(name.to_s + "=") do |value|
          @attributes[name] = attribute.load(value)
        end
      end
    end


    def self.describe(shallow=false)
      hash = super
      
      # Spit attributes if it's the root or if it's an anonymous structures
      if ( !shallow || self.name == nil) && self.attributes
        hash[:attributes] = self.attributes.each_with_object({}) do |(sub_name, sub_attribute), sub_attributes|
          sub_attributes[sub_name] = sub_attribute.describe(true)
        end
      end

      hash
    end


    def self.example(context=nil, **values)
      result = self.new


      context ||= "#{self.name}-#{result.object_id.to_s}"
      example_depth = context.split('.').size


      self.attributes.each do |sub_attribute_name,sub_attribute|
        if sub_attribute.attributes
           # TODO: add option to raise an exception in this case?
           next if example_depth > MAX_EXAMPLE_DEPTH
        end

        sub_context = self.generate_subcontext(context,sub_attribute_name)

        
        result.lazy_attributes[sub_attribute_name] = Proc.new do 
          value = values.fetch(sub_attribute_name) do
            sub_attribute.example(sub_context, parent: result)
          end

          sub_attribute.load(value) 
        end
      end

      result
    end

    def self.dump(value, opts=nil)
      value.dump(opts)
    end

    def self.native_type
      self
    end


    def self.check_option!(name, value)
      case name
      when :identity
        raise AttributorException, "Invalid identity type #{value.inspect}" unless value.kind_of?(::Symbol)
        :ok # FIXME ... actually do something smart, that doesn't break lazy attribute creation
      when :reference
        :ok # FIXME ... actually do something smart
      when :dsl_compiler
        :ok # FIXME ... actually do something smart
      else
        super
      end
    end


    # Model-specific decoding and coercion of the attribute.
    def self.load(value)
      return value if value.nil?
      return value if value.kind_of?(self.native_type)

      hash = case value
      when ::String
        # Strings are assumed to be JSON-serialized for now.
        begin
          JSON.parse(value)
        rescue 
          raise DeserializationError, from: value.class, encoding: "JSON" , value: value            
        end
      when ::Hash
        value
      else
        raise IncompatibleTypeError, value_type: value.class, type: self 
      end

      self.from_hash(hash)
    end


    def self.from_hash(hash)
      model = self.new

      self.attributes.each do |attribute_name, _|
        # OPTIMIZE: deleting the keys as we go is mucho faster, but also very risky
        model.send "#{attribute_name}=", (hash[attribute_name] || hash[attribute_name.to_s])
        # TODO: profile vs the following:
        #model.attributes[attribute_name] = attribute.load(hash[attribute_name] || hash[attribute_name.to_s])
      end
      
      unknown_keys = hash.keys.collect {|k| k.to_sym} - self.attributes.keys
      
      if unknown_keys.any?
        raise AttributorException, "Unknown attributes received: #{unknown_keys.inspect}"
      end

      model
    end

    # method to only define the block of attributes for the model
    # This will be a lazy definition. So we'll only save it in an instance class var for later.
    def self.attributes(opts={},&block)
      if block_given?
        @saved_dsl = block
        @saved_options = opts
      else
        @attributes ||= self.definition.attributes
      end
    end


    def self.options
      # FIXME: this seems like a really dumb way to do this. Needed because definition is lazy.
      @saved_options
      # if @compiled_class_block
      #   @options ||= self.definition.options
      # else
      #   @saved_options
      # end
    end


    def self.validate(object,context,_attribute)
      unless object.kind_of?(self)
        raise ArgumentError, "#{self.name} can not validate object of type #{object.class.name}."
      end

      object.validate(context)
    end


    def self.dsl_class
      @saved_options[:dsl_compiler] || DSLCompiler
    end
    
    # Returns the "compiled" definition for the model.
    # By "compiled" I mean that it will create a new Compiler object with the saved options and saved block that has been passed in the 'attributes' method. This compiled object is memoized (remember, there's one instance of a compiled definition PER MODEL CLASS).
    # TODO: rework this with Model.finalize! support.
    def self.definition( options=nil, block=nil )
      raise AttributorException, "Blueprint structures cannot take extra block definitions" if block
      raise AttributorException, "Models cannot take additional attribute options (options already defined in the Model )" if options

      unless @compiled_class_block
        @compiled_class_block = dsl_class.new(@saved_options)
        @compiled_class_block.parse(&@saved_dsl) if @saved_dsl
      end
      @compiled_class_block
    end


    attr_reader :lazy_attributes, :validating, :dumping


    def initialize( data = nil)

      @lazy_attributes = ::Hash.new
      @validating = false
      @dumping = false
      if data
        loaded = self.class.load( data )
        @attributes = loaded.attributes
      else
        @attributes = ::Hash.new
      end
    end


    # TODO: memoize validation results here, but only after rejiggering how we store the context.
    #       Two calls to validate() with different contexts should return get the same errors, 
    #       but with their respective contexts.
    def validate(context=nil)
      raise AttributorException, "validation conflict" if @validating

      @validating = true

      self.class.attributes.each_with_object(Array.new) do |(sub_attribute_name, sub_attribute), errors|
        sub_context = self.class.generate_subcontext(context,sub_attribute_name)
  
        value = self.send(sub_attribute_name)
        if value.respond_to?(:validating) # really, it's a thing with sub-attributes
          next if value.validating
        end

        errors.push *sub_attribute.validate(self.send(sub_attribute_name), sub_context)
      end
    ensure
      @validating = false
    end


    def attributes
      @lazy_attributes.keys.each do |name|
        self.send(name)  
      end
      @attributes
    end


    def respond_to_missing?(name,*)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      return true if self.class.definition.attributes.key?(attribute_name.to_sym)

      super
    end


    def method_missing(name, *args)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      if self.class.definition.attributes.has_key?(attribute_name.to_sym)
        self.class.define_accessors(attribute_name)
        return self.send(name, *args)
      end

      super
    end


    def dump(opts=nil)
      return CIRCULAR_REFERENCE_MARKER if @dumping

      @dumping = true

      self.attributes.each_with_object({}) do |(name, value), result|
        attribute = self.class.attributes[name]
        result[name.to_sym] = attribute.dump(value)
      end
    ensure
      @dumping = false
    end

  end
end
