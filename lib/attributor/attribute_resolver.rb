require 'ostruct'

module Attributor


  class AttributeResolver
    SEPARATOR = '.'.freeze

    class Data < Hash
      include Hashie::Extensions::MethodReader
    end

    attr_reader :data

    def initialize
      @data = Data.new
    end


    # TODO: support collection queries
    def query!(key_path, path_prefix='$')
      # if the incoming key_path is not an absolute path, append the given prefix
      unless key_path[0] == '$'
        # TODO: prepend '$' to path_prefix if it did not include it? hm.
        key_path = path_prefix + SEPARATOR + key_path
      end

      # discard the initial element, which should always be '$' at this point
      _root, *path = key_path.split(SEPARATOR)

      path.inject(@data) do |hash, key|
        return nil if hash.nil?
        hash.send key
      end
    end


    def query(key_path,path_prefix='$')
      query!(key_path,path_prefix)
    rescue NoMethodError => e
      nil
    end

    def register(key_path, value)
      if key_path.split(SEPARATOR).size > 1
        raise "can only register top-level attributes. got: #{key_path}"
      end

      @data[key_path] = value
    end


    def check(path_prefix, key_path, condition=nil)
      value = self.query(key_path, path_prefix)

      # we have a value, any value, which is good enough given no condition
      if !value.nil? && condition.nil?
        return true
      end


      case condition
      when ::String, ::Regexp, ::Proc
        return condition === value
      when nil
        return !value.nil?
      else
        raise "condition not supported: #{condition.inspect}"
      end

    end


    # TODO: kill this when we also kill Taylor's IdentityMap.current
    def self.current
      Thread.current[:_attributor_attribute_resolver] ||= self.new
    end


    # def self.query(key_path, path_prefix='$')
    #   self.current.query(key_path,path_prefix)
    # end


    # def self.register(key_path, value)
    #   self.current.register(key_path, value)
    # end


    # def self.check(context, key_path, condition=nil)
    #   self.current.check(context,key_path, condition)
    # end

  end

end
