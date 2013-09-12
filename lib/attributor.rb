require 'json'
require 'randexp'

require 'hashie'


module Attributor
  
  require_relative 'attributor/attribute'
  require_relative 'attributor/type'
  require_relative 'attributor/dsl_compiler'
  require_relative 'attributor/attribute_resolver'

  require_relative 'attributor/types/integer'
  require_relative 'attributor/types/string'
  require_relative 'attributor/types/model'
  require_relative 'attributor/types/struct'

  

#  require_relative 'attributor/hash'
#  require_relative 'attributor/array'
#  require_relative 'attributor/csv'
#  require_relative 'attributor/ids'
#  require_relative 'attributor/date_time'
#  require_relative 'attributor/boolean'
  
  
  
  #   def self.demodulized_names
  #     @demodulized_names ||={}
  #   end

  # def self.resolve_class(type, block=nil)
  #   klass = self.determine_class(type)
  #   return klass unless block

  #   raise "Type: #{type} does not support anonymous generation" unless klass.respond_to?(:construct)

  #   klass.construct(block)
  # end


  # def self.find_class(name)
  #   #      klass = demodulized_names[name]
  #   klass ||= const_get(name) if const_defined?(name)
  #   raise "Could not find class with name #{name}" unless klass
  #   raise "Could not find attribute type for: #{name} [klass: #{klass.name}]"  unless  klass < Attributor::Type
  #   klass
  # end

  
  # # IT returns the correct attribute class to be used for instantiation
  # # If it doesn't derive from Attribute, we'll assume there is one with the same name within the Attributor module
  # def self.determine_class(type, block=nil)
  #   return type if type < Attributor::Type
  #   demodulized_class_name = type.name.split("::").last # TOO EXPENSIVE?
  #   Attributor.find_class(demodulized_class_name)
  # end


  def self.resolve_type(type, options={}, block=nil)
    if type < Attributor::Type
      klass = type
    else    
      name = type.name.split("::").last # TOO EXPENSIVE?

      klass ||= const_get(name) if const_defined?(name)
      raise "Could not find class with name #{name}" unless klass
      raise "Could not find attribute type for: #{name} [klass: #{klass.name}]"  unless  klass < Attributor::Type
    end

    return klass unless block

    raise "Type: #{type} does not support anonymous generation" unless klass.respond_to?(:construct)

    klass.construct(block, options)
  end
  


end
