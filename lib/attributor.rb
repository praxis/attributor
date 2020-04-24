require 'json'
require 'randexp'

require 'hashie'

require 'digest/sha1'

module Attributor
  require_relative 'attributor/dumpable'

  require_relative 'attributor/exceptions'
  require_relative 'attributor/attribute'
  require_relative 'attributor/type'
  require_relative 'attributor/dsl_compiler'
  require_relative 'attributor/hash_dsl_compiler'
  require_relative 'attributor/attribute_resolver'
  require_relative 'attributor/smart_attribute_selector'

  require_relative 'attributor/example_mixin'

  require_relative 'attributor/extensions/randexp'

  # hierarchical separator string for composing human readable attributes
  SEPARATOR = '.'.freeze
  DEFAULT_ROOT_CONTEXT = ['$'].freeze

  # @param type [Class] The class of the type to resolve
  #
  def self.resolve_type(attr_type, options = {}, constructor_block = nil)
    klass = self.find_type(attr_type)

    return klass.construct(constructor_block, **options) if klass.constructable?
    raise AttributorException, "Type: #{attr_type} does not support anonymous generation" if constructor_block

    klass
  end

  def self.find_type(attr_type)
    return attr_type if attr_type < Attributor::Type
    name = attr_type.name.split('::').last # TOO EXPENSIVE?

    klass = const_get(name) if const_defined?(name)
    raise AttributorException, "Could not find class with name #{name}" unless klass
    raise AttributorException, "Could not find attribute type for: #{name} [klass: #{klass.name}]" unless klass < Attributor::Type
    klass
  end

  def self.type_name(type)
    return type_name(type.class) unless type.is_a?(::Class)

    type.ancestors.find { |k| k.name && !k.name.empty? }.name
  end

  def self.humanize_context(context)
    return '' unless context

    context = Array(context) if context.is_a? ::String

    unless context.is_a? Enumerable
      raise "INVALID CONTEXT!!! (got: #{context.inspect})"
    end

    begin
      return context.join('.')
    rescue e
      raise "Error creating context string: #{e.message}"
    end
  end

  def self.errorize_value(value)
    inspection = value.inspect
    inspection = inspection[0..500] + '...[truncated]' if inspection.size > 500
    inspection
  end

  MODULE_PREFIX       = 'Attributor::'.freeze
  MODULE_PREFIX_REGEX = ::Regexp.new(MODULE_PREFIX)

  require_relative 'attributor/families/numeric'
  require_relative 'attributor/families/temporal'

  require_relative 'attributor/types/container'
  require_relative 'attributor/types/object'

  require_relative 'attributor/types/bigdecimal'
  require_relative 'attributor/types/integer'
  require_relative 'attributor/types/string'
  require_relative 'attributor/types/symbol'
  require_relative 'attributor/types/boolean'
  require_relative 'attributor/types/time'
  require_relative 'attributor/types/date'
  require_relative 'attributor/types/date_time'
  require_relative 'attributor/types/regexp'
  require_relative 'attributor/types/float'
  require_relative 'attributor/types/collection'
  require_relative 'attributor/types/hash'
  require_relative 'attributor/types/model'
  require_relative 'attributor/types/struct'
  require_relative 'attributor/types/class'
  require_relative 'attributor/types/polymorphic'

  require_relative 'attributor/types/csv'
  require_relative 'attributor/types/ids'

  # TODO: move these to 'optional types' or 'extra types'... location
  require_relative 'attributor/types/tempfile'
  require_relative 'attributor/types/file_upload'
  require_relative 'attributor/types/uri'
end
