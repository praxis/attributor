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



  # List of all basic types (i.e. not collections, structs or models)

  # hierarchical separator string for composing human readable attributes
  SEPARATOR = '.'.freeze
  DEFAULT_ROOT_CONTEXT = ['$'].freeze

  # @param type [Class] The class of the type to resolve
  #
  def self.resolve_type(attr_type, options={}, constructor_block=nil)
    if attr_type < Attributor::Type
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

  def self.humanize_context( context )
    raise "NIL CONTEXT PASSED TO HUMANZE!!" unless context
    raise "INVALID CONTEXT!!! (got: #{context.inspect})" unless context.is_a? Enumerable
    begin
      return context.join('.')
    rescue Exception => e
      raise "Error creating context string: #{e.message}"
    end
  end

  def self.errorize_value( value )
    inspection =value.inspect
    inspection = inspection[0..500]+ "...[truncated]" if inspection.size>500
    inspection
  end

  MODULE_PREFIX       = "Attributor\:\:".freeze
  MODULE_PREFIX_REGEX = Regexp.new(MODULE_PREFIX)

  require_relative 'attributor/types/container'
  require_relative 'attributor/types/object'
  require_relative 'attributor/types/integer'
  require_relative 'attributor/types/string'
  require_relative 'attributor/types/model'
  require_relative 'attributor/types/struct'
  require_relative 'attributor/types/boolean'
  require_relative 'attributor/types/date_time'
  require_relative 'attributor/types/float'
  require_relative 'attributor/types/collection'
  require_relative 'attributor/types/hash'


  require_relative 'attributor/types/csv'
  require_relative 'attributor/types/ids'

  # TODO: move these to 'optional types' or 'extra types'... location
  require_relative 'attributor/types/tempfile'
  require_relative 'attributor/types/file_upload'


end
