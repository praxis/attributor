
  module Attributor
    
#   def self.demodulized_names
#     @demodulized_names ||={}
#   end
    
    def self.find_class(name)
#      klass = demodulized_names[name]
      klass ||= const_get(name) if const_defined?(name)
      raise "Could not find class with name #{name}" unless klass
      raise "Could not find attribute type for: #{name} [klass: #{klass.name}]"  unless  klass < Attributor::Base
      klass
    end
    # IT returns the correct attribute class to be used for instantiation
    # If it doesn't derive from Attribute, we'll assume there is one with the same name within the Attributor module
    def self.determine_class(type)
      puts "TYPE: #{type}"
      return type if type < Attributor::Base    
      demodulized_class_name = type.name.split("::").last # TOO EXPENSIVE?
      Attributor.find_class(demodulized_class_name)
    end
    
    # It is the abstract base class to hold an attribute, both a leaf and a container (hash/Array...)
    # TODO: should this be a mixin since it is an abstract class?
    class Attribute
      
      # hierarchical separator string for composing human readable attributes 
      SEPARATOR = '.'
      
      attr_reader :type
      
      # 
      # @options: metadata about the attribute
      # @block: code definition for struct attributes (nil for predefined types or leaf/simple types)
      def initialize(type, opts, &block)
        @type = Attributor::determine_class(type)
        @options = opts.dup if opts
        @saved_block = block
#        @inherit_from = @options.delete(:inherit_from) # AttributeType object to inherit options/subdefinitions from
        processed = @type.validate_universal_options(@options)
  
        remaining = @options.reject{|key,_| processed.include? key } 
        @type.validate_options( remaining ) if @type.respond_to? :validate_options
      end
      
    # LAzy compilation
   def compiled_definition
     unless @compiled_definition
       @compiled_definition = type.definition( @options, @saved_block )
       @compiled_options = @compiled_definition.options.merge(@options)
     end
     @compiled_definition
   end

   def options
     if type < Model
       compiled_definition unless @compiled_definition
       @compiled_options
     else # Simple, no DSL anywhere type
       @options
     end
   end
   
     def attributes
       compiled_definition.attributes
     end

#    def check_dependencies(myself, root, definition)
#      @type.check_dependencies(myself, root, definition)
#    end


     ########################################
     # Main client API methods
     ########################################     
     def describe
       type.describe( self ) # Pass the whole attribute instance (which contains, definition, options..etc)
     end
     
     def parse( val )
       object, errors = load(value, nil, self)
       return [ nil , errors ] if errors.any?
       
       errors += new_validate(object, nil, self) 
       [ object, errors ]
     end
     
     # TODO:  might want to expose "load directly too?..."
     def load( val )
       type.load(val, nil, self)
     end
     
     def validate( val )
       type.new_validate( val, nil, self, nil ) )
     end

    end   
  end
