#Container of options and structure definition
class DSLCompiler
  
  attr_accessor :attributes, :options
  
  def initialize(options={})
    @options = options
    @attributes={}
  end
  
  def parse(&block)
    self.instance_eval(&block) if block
    return self
  end

  
  # Hash definitions support "attribute", [Type], options, (block)
  # Which can define the attributes possible in the hash and their format (can be recursive)
  # Each attribute will create an attribute and save it on the "definition" piece.
  def attribute(name, type, opts={}, &block)
    raise "Attribute #{name} already defined" if attributes.has_key? name        
    
    klass = Attributor.determine_class(type)        
#    opts[:inherit_from] = @inherit_from[name] if @inherit_from
    attributes[name] = Attributor::Attribute.new(klass, opts, &block)
  end
  alias_method :param, :attribute
  
  
  def private_decode_args_for_attribute( incoming_type, incoming_opts)
    if( incoming_type == nil )
      type = nil
      opts = incoming_opts.dup
    elsif( incoming_type.is_a?(::Hash) )
      type = nil
      opts = incoming_type.dup
    else
      type = incoming_type
      opts = incoming_opts.dup
    end        
    { :type => type, :opts=>opts }
  end
  
  def describe_attributes    
    sub_definition = {}
    attributes.each do |name, object|
      sub_definition[name] = object.describe
    end
    sub_definition
  end
end