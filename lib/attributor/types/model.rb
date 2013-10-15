

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
      attribute_name.sub!('=','')

      return true if self.class.definition.attributes.key?(attribute_name)

      super
    end


    def method_missing(name, *args)
      attribute_name = name.to_s
      attribute_name.sub!('=','')

      if attribute = self.class.definition.attributes[attribute_name]
        if name.to_s[-1] == '='
          value, *rest = args
          return attributes[attribute_name]  = attribute.load(value)
        else
          return attributes[attribute_name]
        end
      end

      super
    end


    module ClassMethods


      def example(options={}, context=nil)
        result = self.new

        self.definition.attributes.each do |attribute_name,attribute|
          sub_context = self.generate_subcontext(context,attribute_name)
          result.send("#{attribute_name}=", attribute.example(context))
        end

        result
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

        (hash.keys | self.definition.attributes.keys).each do |k|
          model.send("#{k}=", hash[k])
        end

        model
      end

      # method to only define the block of attributes for the model
      # This will be a lazy definition. So we'll only save it in an instance class var for later.
      def attributes(opts={},&block)
        raise AttributorException.new("There is no getter for attributes here (go through definition.attributes)") unless block_given?
        @saved_dsl = block
        @saved_options = opts
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
