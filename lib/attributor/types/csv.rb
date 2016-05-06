module Attributor
  class CSV < Collection
    def self.decode_string(value, _context)
      value.split(',')
    end

    def self.dump(values, **opts)
      case values
      when ::String
        values
      when ::Array
        values.collect { |value| member_attribute.dump(value, opts).to_s }.join(',')
      when nil
        nil
      else
        context = opts[:context] || DEFAULT_ROOT_CONTEXT
        name =  context.last.to_s
        type = values.class.name
        reason = 'Attributor::CSV only supports dumping values of type ' \
                 "Array or String, not #{values.class.name}."
        raise DumpError.new(context: context, name: name, type: type, original_exception: reason)
      end
    end

    def self.example(context = nil, options: {})
      collection = super(context, options: options.merge(size: (2..4)))
      collection.join(',')
    end

    def self.describe(shallow = false, example: nil)
      hash = super(shallow)
      hash.delete(:member_attribute)
      hash[:example] = example if example
      hash
    end

    def self.family
      Collection.family
    end
  end
end
