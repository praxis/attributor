module Attributor
  class SmartAttributeSelector
    attr_accessor :reqs, :accepted, :banned, :remaining
    attr_reader :reqs, :accepted, :banned, :remaining, :keys_with_values

    def initialize( reqs , attributes, values)
      @reqs = reqs.dup
      @accepted = []
      @banned = []
      @remaining = Array.new(attributes.dup)
      @keys_with_values = values.each_with_object([]){|(k,v),populated| populated.push(k) unless v == nil}
    end

    def process
      process_required
      process_exclusive
      process_at_least
      # Just add the ones that haven't been explicitly rejected
      self.accepted += self.remaining
      self.remaining = []
      self.accepted = self.accepted.uniq
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
           (req[:type] == :exactly && req[:count] == 1 ) ||
           (req[:type] == :at_most && req[:count] == 1 )
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

     #################

     def process_exclusive_set( exclusive_set )
       feasible = exclusive_set - banned # available ones to pick (that are not banned)
       # Try to favor attributes that come in with some values, otherwise get the first feasible one
       preferred = feasible & keys_with_values
       pick = (preferred.size == 0 ? feasible : preferred).shift

       if pick
         self.accepted.push( pick )
       else
         puts "Unfeasible!" unless exclusive_set.empty?
         return
       end
       self.banned += feasible
       self.remaining -= exclusive_set
     end

     def process_at_least_set( at_least_set, count)
       feasible = at_least_set - banned # available ones to pick (that are not banned)
       preferred = (feasible & keys_with_values)[0,count]
       # Add more if not enough
       pick = if preferred.size < count
         preferred + (feasible - preferred)[0,count-preferred.size]
       else
         preferred
       end

       unless pick.size == count
         puts "Unfeasible!"
         return
       end
       self.accepted += pick
       self.remaining -= pick
     end

     def print_status
       puts "REMAINING: #{remaining.inspect}"
       puts "ACCEPTED : #{accepted.inspect}"
       puts "BANNED   : #{banned.inspect}"
     end
  end
end