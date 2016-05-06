require_relative 'dsl_compiler'

module Attributor
  class HashDSLCompiler < DSLCompiler
    # A class that encapsulates the definition of a requirement for Hash attributes
    # It implements the validation against incoming values and it describes its format for documentation purposes
    class Requirement
      attr_reader :type
      attr_reader :number
      attr_reader :attr_names
      attr_reader :description

      def initialize(description: nil, **spec)
        @description = description
        @type = spec.keys.first
        case type
        when :all
          of(*spec[type])
        when :exclusive
          of(*spec[type])
        else
          @number = spec[type]
        end
      end

      def of(*args)
        @attr_names = args
        self
      end

      def validate(object, context = Attributor::DEFAULT_ROOT_CONTEXT, _attribute = nil)
        result = []
        case type
        when :all
          rest = attr_names - object.keys
          unless rest.empty?
            rest.each do |attr|
              result.push "Key #{attr} is required for #{Attributor.humanize_context(context)}."
            end
          end
        when :exactly
          included = attr_names & object.keys
          unless included.size ==  number
            result.push "Exactly #{number} of the following keys #{attr_names} are required for #{Attributor.humanize_context(context)}. Found #{included.size} instead: #{included.inspect}"
          end
        when :at_most
          rest = attr_names & object.keys
          if rest.size > number
            found = rest.empty? ? 'none' : rest.inspect
            result.push "At most #{number} keys out of #{attr_names} can be passed in for #{Attributor.humanize_context(context)}. Found #{found}"
          end
        when :at_least
          rest = attr_names & object.keys
          if rest.size < number
            found = rest.empty? ? 'none' : rest.inspect
            result.push "At least #{number} keys out of #{attr_names} are required to be passed in for #{Attributor.humanize_context(context)}. Found #{found}"
          end
        when :exclusive
          intersection = attr_names & object.keys
          if intersection.size > 1
            result.push "keys #{intersection.inspect} are mutually exclusive for #{Attributor.humanize_context(context)}."
          end
        end
        result
      end

      def describe(_shallow = false, _example: nil)
        hash = { type: type, attributes: attr_names }
        hash[:count] = number unless number.nil?
        hash[:description] = description unless description.nil?
        hash
      end
    end

    # A class that encapsulates the available DSL under the `requires` keyword.
    # In particular it allows to define requirements like:
    # requires.all :attr1, :attr2, :attr3
    # requires.exclusive :attr1, :attr2, :attr3
    # requires.at_most(2).of :attr1, :attr2, :attr3
    # requires.at_least(2).of :attr1, :attr2, :attr3
    # requires.exactly(2).of :attr1, :attr2, :attr3
    # Note: all and exclusive can also use .of , it is equivalent
    class RequiresDSL
      attr_accessor :target
      attr_accessor :options
      def initialize(target, **opts)
        self.target = target
        self.options = opts
      end

      def all(*attr_names, **opts)
        req = Requirement.new(options.merge(opts).merge(all: attr_names))
        target.add_requirement req
        req
      end

      def at_most(number)
        req = Requirement.new(options.merge(at_most: number))
        target.add_requirement req
        req
      end

      def at_least(number)
        req = Requirement.new(options.merge(at_least: number))
        target.add_requirement req
        req
      end

      def exactly(number)
        req = Requirement.new(options.merge(exactly: number))
        target.add_requirement req
        req
      end

      def exclusive(*attr_names, **opts)
        req = Requirement.new(options.merge(opts).merge(exclusive: attr_names))
        target.add_requirement req
        req
      end
    end

    def _requirements_dsl
      @requirements_dsl ||= RequiresDSL.new(@target)
    end

    def requires(*spec, **opts, &block)
      if spec.empty?
        _requirements_dsl.options.merge(opts) unless opts.empty?
        if block_given?
          _requirements_dsl.instance_eval(&block)
        else
          _requirements_dsl
        end
      else
        _requirements_dsl.all(*spec, opts)
      end
    end
  end
end
