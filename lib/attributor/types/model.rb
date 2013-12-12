

module Attributor
  module Model

    def self.included(klass)
      klass.module_eval do
        include Attributor::Type
      end
      klass.extend(ClassMethods)
    end



    def attributes
      @attributes ||= Hash.new
    end


    def respond_to?(name, include_private = false)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      return true if self.class.definition.attributes.key?(attribute_name)

      super
    end


    def method_missing(name, *args)
      attribute_name = name.to_s
      attribute_name.chomp!('=')

      if self.class.definition.attributes.has_key?(attribute_name)
        self.class.define_accessors(attribute_name)
        return self.send(name, *args)
      end

      super
    end


    def dump(opts=nil)
      result = {}
      
      self.attributes.each do |name, value|
        attribute = self.class.attributes[name]
        result[name.to_sym] = attribute.dump(value)
      end
    
      result
    end


    module ClassMethods

      # Define accessors for attribute of given name.
      #
      # @param name [::String, ::Symbol] attribute name, converted to String before use.
      #
      def define_accessors(name)
        name = name.to_s
        self.define_reader(name)
        self.define_writer(name)
      end

      def define_reader(name)
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{name}
           attributes['#{name}']
          end
        RUBY
      end

      def define_writer(name)
        attribute = self.attributes[name]
        # note: paradoxically, using define_method ends up being faster for the writer
        #       attribute is captured by the block, saving us from having to retrieve it from
        #       the class's attributes hash on each write.
        module_eval do
          define_method(name + "=") do |value|
            attributes[name] = attribute.load(value)
          end
        end

      end


      def example(context=nil, options={})
        result = self.new

        context ||= result.object_id.to_s

        self.attributes.each do |attribute_name,attribute|
          sub_context = self.generate_subcontext(context,attribute_name)
          result.send("#{attribute_name}=", attribute.example(sub_context, result))
        end

        result
      end

      def dump(value, opts=nil)
        value.dump(opts)
      end

      def native_type
        self
      end


      def check_option!(name, value)
        case name
        when :identity
          raise AttributorException.new("Invalid identity type #{value.inspect}") unless value.kind_of?(::String) || value.kind_of?(::Symbol)
          if self.definition.attributes.has_key?(value.to_s)
            :ok
          else
            raise AttributorException.new("Identity attribute #{value.inspect} for #{self.name} not found")
          end
        when :reference
          :ok # FIXME ... actually do something smart
        else
          super
        end
      end


      # Model-specific decoding and coercion of the attribute.
      def load(value)
        return value if value.nil?
        return value if value.kind_of?(self.native_type)

        hash = case value
        when ::String
          # Strings are assumed to be JSON-serialized for now.
          JSON.parse(value)
        when ::Hash
          value
        else
          raise AttributorException.new(
            "Can not load #{self} from value #{value.inspect} of type #{value.class}"
          )
        end

        self.from_hash(hash)
      end


      def from_hash(hash)
        model = self.new

        self.attributes.keys.each do |k|
          # OPTIMIZE: deleting the keys as we go is mucho faster, but also very risky
          model.send "#{k}=", (hash[k] || hash[k.to_sym])
        end
        
        unknown_keys = hash.keys.collect {|k| k.to_s} - self.attributes.keys
        
        if unknown_keys.any?
          raise AttributorException.new("Unknown attributes received: #{unknown_keys.inspect}")
        end

        model
      end

      # method to only define the block of attributes for the model
      # This will be a lazy definition. So we'll only save it in an instance class var for later.
      def attributes(opts={},&block)
        if block_given?
          @saved_dsl = block
          @saved_options = opts
        else
          @attributes ||= self.definition.attributes
        end
      end


      def options
        # FIXME: this seems like a really dumb way to do this. 
        @saved_options
        # if @compiled_class_block
        #   @options ||= self.definition.options
        # else
        #   @saved_options
        # end
      end


      def validate(object,context,attribute)
        errors = super

        self.attributes.each do |sub_attribute_name, sub_attribute|
          sub_context = self.generate_subcontext(context,sub_attribute_name)
          errors += sub_attribute.validate(object.send(sub_attribute_name), sub_context)
        end

        errors
      end

      # Returns the "compiled" definition for the model.
      # By "compiled" I mean that it will create a new Compiler object with the saved options and saved block that has been passed in the 'attributes' method. This compiled object is memoized (remember, there's one instance of a compiled definition PER MODEL CLASS).
      def definition( options=nil, block=nil )
        raise AttributorException.new("Blueprint structures cannot take extra block definitions") if block
        raise AttributorException.new("Models cannot take additional attribute options (options already defined in the Model )") if options

        unless @compiled_class_block
          @compiled_class_block = DSLCompiler.new(@saved_options)
          @compiled_class_block.parse(&@saved_dsl) if @saved_dsl
        end
        @compiled_class_block
      end

    end


  end
end
