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

  require_relative 'attributor/types/container'
  require_relative 'attributor/types/object'
  require_relative 'attributor/types/integer'
  require_relative 'attributor/types/string'
  require_relative 'attributor/types/model'
  require_relative 'attributor/types/struct'
  require_relative 'attributor/types/polymorphic'
  require_relative 'attributor/types/boolean'
  require_relative 'attributor/types/date_time'
  require_relative 'attributor/types/float'
  require_relative 'attributor/types/collection'
  require_relative 'attributor/types/hash'
  require_relative 'attributor/types/csv'
  require_relative 'attributor/types/ids'

  # List of all basic types (i.e. not collections, structs or models)

  # hierarchical separator string for composing human readable attributes
  SEPARATOR = '.'.freeze

  # @param type [Class] The class of the type to resolve
  #
  def self.resolve_type(attr_type, options={}, constructor_block=nil)
    if attr_type < Attributor::Type || attr_type < Attributor::Polymorphic #FIXME: think about what's the right check here...
      klass = attr_type
    else
      name = attr_type.name.split("::").last # TOO EXPENSIVE?

      klass = const_get(name) if const_defined?(name)
      raise AttributorException.new("Could not find class with name #{name}") unless klass
      raise AttributorException.new("Could not find attribute type for: #{name} [klass: #{klass.name}]")  unless  klass < Attributor::Type
    end

    if klass.respond_to?(:construct)
      return klass.construct(constructor_block, options)
    end

    raise AttributorException.new("Type: #{attr_type} does not support anonymous generation") if constructor_block

    klass
  end
  

  MODULE_PREFIX       = "Attributor\:\:".freeze
  MODULE_PREFIX_REGEX = Regexp.new(MODULE_PREFIX)

end
