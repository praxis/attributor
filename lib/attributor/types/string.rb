module Attributor
  class String
    include Type

    def self.native_type
      ::String
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      if value.is_a?(Enumerable)
        raise IncompatibleTypeError.new(context: context, value_type: value.class, type: self)
      end

      value && String(value)
    rescue
      super
    end

    def self.example(_context = nil, options: {})
      Faker::Lorem.word
    end

    def self.family
      'string'
    end

    def self.json_schema_type
      :string
    end
    
    # TODO: we're passing the attribute options for now...might need to rethink ...although these are type-specific...
    # TODO: multipleOf, minimum, maximum, exclusiveMinimum and exclusiveMaximum
    def self.as_json_schema( shallow: false, example: nil, attribute_options: {} )
      h = super
      opts = ( self.respond_to?(:options) ) ? self.options.merge( attribute_options ) : attribute_options
      h[:pattern] = self.human_readable_regexp(opts[:regexp]) if opts[:regexp]
      # TODO: minLength, maxLength
      h
    end

    def self.human_readable_regexp( reg )
      return $1 if reg.to_s =~ /\(\?[^:]+:(.+)\)/
      reg
    end
  end
end
