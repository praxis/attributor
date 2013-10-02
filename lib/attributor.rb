require 'json'
require 'randexp'

require 'hashie'

require 'digest/sha1'

module Attributor

  require_relative 'attributor/exceptions'
  require_relative 'attributor/attribute'
  require_relative 'attributor/type'
  require_relative 'attributor/dsl_compiler'
  require_relative 'attributor/attribute_resolver'

  require_relative 'attributor/extensions/randexp'

  require_relative 'attributor/types/integer'
  require_relative 'attributor/types/string'
  require_relative 'attributor/types/model'
  require_relative 'attributor/types/struct'
  require_relative 'attributor/types/boolean'
  require_relative 'attributor/types/date_time'
  require_relative 'attributor/types/float'
  require_relative 'attributor/types/collection'

  # List of all basic types (i.e. not collections, structs or models)
  BASIC_TYPES = [
    Attributor::Integer,
    Attributor::String,
    Attributor::Boolean,
    Attributor::DateTime,
    Attributor::Float
  ].freeze

  # hierarchical separator string for composing human readable attributes
  SEPARATOR = '.'.freeze

  def self.resolve_type(type, options={}, constructor_block=nil)
    if type < Attributor::Type
      klass = type
    else
      name = type.name.split("::").last # TOO EXPENSIVE?

      klass = const_get(name) if const_defined?(name)
      raise AttributorException.new("Could not find class with name #{name}") unless klass
      raise AttributorException.new("Could not find attribute type for: #{name} [klass: #{klass.name}]")  unless  klass < Attributor::Type
    end

    return klass unless constructor_block

    raise AttributorException.new("Type: #{type} does not support anonymous generation") unless klass.respond_to?(:construct)

    klass.construct(constructor_block, options)
  end

end
