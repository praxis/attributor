# poorly-optimized, but handy, mixin for Hash and Model examples.
# primarily enables support for lazy values.

module Attributor

  module ExampleMixin

    def self.extended(obj)
      if obj.kind_of? Attributor::Model
        obj.class.attributes.each do |name, _|
          obj.define_singleton_method(name) do
            get(name)
          end
        end
      end
    end

    def lazy_attributes
      @lazy_attributes ||= {}
    end

    def lazy_attributes=(val)
      @lazy_attributes = val
    end

    def [](k)
      unless @contents.key?(k)
        proc = lazy_attributes.delete k
        @contents[k] = proc.call
      end
      @contents[k]
    end

    def []=(k,v)
      lazy_attributes.delete k
      @contents[k] = v
    end

    def each(&block)
      contents.each(&block)
    end

    alias_method :each_pair, :each

    def values
      contents.values
    end

    def empty?
      contents.empty?
    end

    def size
      keys.size
    end

    def keys
      @contents.keys | lazy_attributes.keys
    end

    def key?(key)
      @contents.key?(key) || lazy_attributes.key?(key)
    end

    def get(key, context: self.generate_subcontext(Attributor::DEFAULT_ROOT_CONTEXT,key))
      key = self.class.key_attribute.load(key, context)

      unless @contents.key? key
        if lazy_attributes.key?(key)
          proc = lazy_attributes.delete(key)
          @contents[key] = proc.call(self)
        end
      end

      super
    end

    def attributes
      lazy_attributes.keys.each do |name|
        self.__send__(name)
      end

      super
    end

    def contents
      lazy_attributes.keys.each do |key|
        proc = lazy_attributes.delete(key)
        @contents[key] = proc.call(self) unless @contents.key?(key)
      end

      super
    end
  end

end
