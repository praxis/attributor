module Attributor

  class CSV < Collection

    def self.decode_string(value,context)
      value.split(',')
    end

    def self.example(context=nil, options: {})
      collection = []
      while collection.size < 2
        collection = super(context, options)
      end
      return collection.join(',')
    end

  end
end
