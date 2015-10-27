require_relative 'dsl_compiler'


module Attributor

  class HashDSLCompiler < DSLCompiler

    class Requirement
      attr_reader :type
      attr_reader :number
      attr_reader :attr_names

      def initialize(spec)
        @type = spec.keys.first
        case type
        when :all
          self.of(*spec[type])
        when :exclusive
          self.of(*spec[type])
        else
          @number = spec[type]
        end
      end
      def of( *args)
        @attr_names = args
        self
      end

      def validate( object,context=Attributor::DEFAULT_ROOT_CONTEXT,_attribute)
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
            found = rest.empty? ? "none" : rest.inspect
            result.push "At most #{number} keys out of #{attr_names} can be passed in for #{Attributor.humanize_context(context)}. Found #{found}"
          end
        when :at_least
          rest = attr_names & object.keys
          if rest.size < number
            found = rest.empty? ? "none" : rest.inspect
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
    end


    class RequiresDSL
      attr_accessor :target
      def initialize(target)
        self.target = target
      end
      def all(*attr_names)
        req = Requirement.new( all: attr_names )
        target.add_requirement req
        req
      end
      def at_most(number)
        req = Requirement.new( at_most: number )
        target.add_requirement req
        req
      end
      def at_least(number)
        req = Requirement.new( at_least: number )
        target.add_requirement req
        req
      end
      def exactly(number)
        req = Requirement.new( exactly: number )
        target.add_requirement req
        req
      end
      def exclusive(*attr_names)
        req = Requirement.new( exclusive: attr_names )
        target.add_requirement req
        req
      end

    end

    def _requirements_dsl
      @requirements_dsl ||= RequiresDSL.new(@target)
    end

    def requires(*spec,&block)
      if spec.empty?
        if block_given?
          self._requirements_dsl.instance_eval(&block)
        else
          self._requirements_dsl
        end
      else
        self._requirements_dsl.all(*spec)
      end
    end


  end
end