
module Attributor
  class Struct 
    include Attributor::Model

    # Construct a new subclass, using attribute_definition to define attributes.
    def self.construct(attribute_definition, options={})
      # TODO: massage the options here to pull out only the relevant ones
      Class.new(self) do
        attributes options, &attribute_definition
      end
    end

  end
end

#     def initialize(definition)
#       # Initialize methods based on definition
#       @definition = definition.attributes
#       @value = {}
#     end
    
#     # FIXME: is this confusing? this is just to get the underlying attributes hash of the instahce...
#     def attributes
#       @value
#     end
    
# #    def method_missing( name, *args)
# #      name = name.to_s
# #      if name[-1] == "="
# #        attr_name = name[0..-2]
# ##        puts "TRYING TO SET #{name.inspect} (haskey: #{@definition.has_key?(attr_name)})for #{self.inspect}"
# #        super unless @definition.has_key? attr_name
# #        @value[attr_name] = args.first
# #      else
# ##        puts "TRYING TO GET #{name.inspect} (haskey: #{@definition.has_key?(name)})for #{self}"
# #        super unless @definition.has_key? name
# #        return @value[name]
# #      end
# #    end
# #    
# #    def self.definition( options=nil, block=nil )
# #      raise "Anon Struct must be defined with a block" unless block
# #      # Anon structs cannot memoize the compiled block (but attribute will do it)
# #      compiler = DSLCompiler.new(options)
# #      compiler.parse(&block)
# #      compiler
# #    end
    
#     def self.attributes()
#       raise "NOO! There is no DSL for this in Anon!"
#     end
    
#     def new_for_attribute( attribute )
#       self.new(attribute)
#     end
    
#     def self.decode_from_hash(value,context,attribute=self.definition)
#       puts "STRUCT: DECODE FROM HASH: #{value.inspect}"
#       inst = self.new(attribute)
#       errors = []
#       value.each_pair do |k,v|
#         subattr = attribute.attributes[k]
#         if subattr
#           sub_context = generate_subcontext(context,k)
#           parsed_value, e = subattr.type.load( v , sub_context , subattr ) #TOCHECK: Calling load since we don't want to call parse cause it checks dependencies...and not all is loaded yet
# #          raise "FIXME: Error parsing attribute #{k} of #{context}: #{e}" unless e.empty?
#           if e.empty?
#             inst.send("#{k}=", parsed_value )# TODO: need a generic way to set attrs...is this it?
#           else
#             errors += e
#           end
#         else
#           #TODO: do not blindly set the attribute. Perhaps we need a white/blacklist option to control that: inst.send("#{k}=", v )
#         end
#       end
#       puts "RETURNING: ERRS: for #{value} -> #{errors}" unless errors.empty?
#       [inst, errors]
#     end
    
#   end

#end
