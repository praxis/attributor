require 'json'
require 'randexp'

require 'hashie'

require 'digest/sha1'

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

  # hierarchical separator string for composing human readable attributes
  SEPARATOR = '.'.freeze

  def self.resolve_type(type, options={}, constructor_block=nil)
    if type < Attributor::Type
      klass = type
    else
      name = type.name.split("::").last # TOO EXPENSIVE?

      klass = const_get(name) if const_defined?(name)
      raise "Could not find class with name #{name}" unless klass
      raise "Could not find attribute type for: #{name} [klass: #{klass.name}]"  unless  klass < Attributor::Type
    end

    return klass unless constructor_block

    raise "Type: #{type} does not support anonymous generation" unless klass.respond_to?(:construct)

    klass.construct(constructor_block, options)
  end



end
