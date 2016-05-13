require 'ostruct'

module Attributor
  class AttributeResolver
    ROOT_PREFIX = '$'.freeze
    COLLECTION_INDEX_KEY = /^at\((\d+)\)$/

    class Data < ::Hash
      include Hashie::Extensions::MethodReader
    end

    attr_reader :data

    def initialize
      @data = Data.new
    end

    def query!(key_path, path_prefix = ROOT_PREFIX)
      # If the incoming key_path is not an absolute path, append the given prefix
      # NOTE: Need to index key_path by range here because Ruby 1.8 returns a
      # FixNum for the ASCII code, not the actual character, when indexing by a number.
      unless key_path[0..0] == ROOT_PREFIX
        # TODO: prepend path_prefix to path_prefix if it did not include it? hm.
        key_path = path_prefix + SEPARATOR + key_path
      end

      # Discard the initial element, which should always be ROOT_PREFIX at this point
      _root, *path = key_path.split(SEPARATOR)

      # Follow the hierarchy path to the requested node and return it:
      # Example path => ["instance", "ssh_key", "name"]
      # Example @data => {"instance" => { "ssh_key" => { "name" => "foobar" } }}
      #
      # at(n) is a collection index:
      # Example path => ["filters", "at(0)", "type"]
      # Example data => {"filters" => [{ "type" => "instance:tag" }]}
      #
      result = path.inject(@data) do |hash, key|
        return nil if hash.nil?
        if (match = key.match(COLLECTION_INDEX_KEY))
          hash[match[1].to_i]
        else
          hash.send key
        end
      end
      result
    end

    # Query for a certain key in the attribute hierarchy
    #
    # @param [String] key_path The name of the key to query and its path
    # @param [String] path_prefix
    #
    # @return [String] The value of the specified attribute/key
    #
    def query(key_path, path_prefix = ROOT_PREFIX)
      query!(key_path, path_prefix)
    rescue NoMethodError
      nil
    end

    def register(key_path, value)
      if key_path.split(SEPARATOR).size > 1
        raise AttributorException, "can only register top-level attributes. got: #{key_path}"
      end

      @data[key_path] = value
    end

    # Checks that the the condition is met. This means the attribute identified
    # by path_prefix and key_path satisfies the optional predicate, which when
    # nil simply checks for existence.
    #
    # @param path_prefix [String]
    # @param key_path [String]
    # @param predicate [String|Regexp|Proc|NilClass]
    #
    # @returns [Boolean] True if :required_if condition is met, false otherwise
    #
    # @raise [AttributorException] When an unsupported predicate is passed
    #
    def check(path_prefix, key_path, predicate = nil)
      value = query(key_path, path_prefix)

      # we have a value, any value, which is good enough given no predicate
      return true if !value.nil? && predicate.nil?

      case predicate
      when ::String, ::Regexp, ::Integer, ::Float, ::DateTime, true, false
        return predicate === value
      when ::Proc
        # Cannot use === here as above due to different behavior in Ruby 1.8
        return predicate.call(value)
      when nil
        return !value.nil?
      else
        raise AttributorException, "predicate not supported: #{predicate.inspect}"
      end
    end

    # TODO: kill this when we also kill Taylor's IdentityMap.current
    def self.current=(resolver)
      Thread.current[:_attributor_attribute_resolver] = resolver
    end

    def self.current
      raise AttributorException, 'No AttributeResolver set.' unless Thread.current[:_attributor_attribute_resolver]
      Thread.current[:_attributor_attribute_resolver]
    end
  end
end
