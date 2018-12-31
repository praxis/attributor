# frozen_string_literal: true

module Attributor
  class SmartAttributeSelector
    attr_accessor :reqs, :accepted, :banned, :remaining
    attr_reader :reqs, :accepted, :banned, :remaining, :keys_with_values

    def initialize(reqs, attributes, values)
      @reqs = reqs.dup
      @accepted = []
      @banned = []
      @remaining = attributes.dup
      @keys_with_values = values.each_with_object([]) { |(k, v), populated| populated.push(k) unless v.nil? }
    end

    def process
      process_required
      process_exclusive
      process_exactly
      process_at_least
      process_at_most
      # Just add the ones that haven't been explicitly rejected
      self.accepted += self.remaining
      self.remaining = []
      self.accepted.uniq!
      self.accepted
    end

    def process_required
      self.reqs = reqs.each_with_object([]) do |req, rest|
        if req[:type] == :all
          self.accepted += req[:attributes]
          self.remaining -= req[:attributes]
        else
          rest.push req
        end
      end
    end

    def process_exclusive
      self.reqs = reqs.each_with_object([]) do |req, rest|
        if req[:type] == :exclusive ||
           (req[:type] == :exactly && req[:count] == 1) ||
           (req[:type] == :at_most && req[:count] == 1)
          process_exclusive_set(Array.new(req[:attributes]))
        else
          rest.push req
        end
      end
    end

    def process_at_least
      self.reqs = reqs.each_with_object([]) do |req, rest|
        if req[:type] == :at_least
          process_at_least_set(Array.new(req[:attributes]), req[:count])
        else
          rest.push req
        end
      end
    end

    def process_at_most
      self.reqs = reqs.each_with_object([]) do |req, rest|
        if req[:type] == :at_most && req[:count] > 1 # count=1 is already handled in exclusive
          process_at_most_set(Array.new(req[:attributes]), req[:count])
        else
          rest.push req
        end
      end
    end

    def process_exactly
      self.reqs = reqs.each_with_object([]) do |req, rest|
        if req[:type] == :exactly && req[:count] > 1 # count=1 is already handled in exclusive
          process_exactly_set(Array.new(req[:attributes]), req[:count])
        else
          rest.push req
        end
      end
    end

    #################

    def process_exclusive_set(exclusive_set)
      feasible = exclusive_set - banned # available ones to pick (that are not banned)
      # Try to favor attributes that come in with some values, otherwise get the first feasible one
      preferred = feasible & keys_with_values
      pick = (preferred.size.zero? ? feasible : preferred).first

      if pick
        self.accepted.push(pick)
      else
        raise UnfeasibleRequirementsError unless exclusive_set.empty?
      end
      self.banned += (feasible - [pick])
      self.remaining -= exclusive_set
    end

    def process_at_least_set(at_least_set, count)
      feasible = at_least_set - banned # available ones to pick (that are not banned)
      preferred = (feasible & keys_with_values)[0, count]
      # Add more if not enough
      pick = if preferred.size < count
               preferred + (feasible - preferred)[0, count - preferred.size]
             else
               preferred
             end

      raise UnfeasibleRequirementsError unless pick.size == count

      self.accepted += pick
      self.remaining -= pick
    end

    def process_at_most_set(set, count)
      ceil = (count + 1) / 2
      feasible = set - banned # available ones to pick (that are not banned)
      preferred = (feasible & keys_with_values)[0, ceil]

      pick = if preferred.size < ceil
               preferred + (feasible - preferred)[0, ceil - preferred.size]
             else
               preferred
             end

      self.accepted += pick
      self.remaining -= pick
    end

    def process_exactly_set(set, count)
      feasible = set - banned # available ones to pick (that are not banned)
      preferred = (feasible & keys_with_values)[0, count]

      pick = if preferred.size < count
               preferred + (feasible - preferred)[0, count - preferred.size]
             else
               preferred
             end

      raise UnfeasibleRequirementsError unless pick.size == count

      self.accepted += pick
      self.remaining -= pick
    end
  end
end
