# Represents a plain old boolean type. TBD: can be nil?
#
require_relative '../exceptions'

module Attributor

    class DateTime
      include Type

      # Note: cannot use DateTime.new - causes error in some rubies
      # Example error:
      # ruby 1.9.2p290 (2011-07-09 revision 32553) [x86_64-linux]
      # Linux ci-linux-1.test.rightscale.com 2.6.32-345-ec2 #49-Ubuntu SMP Fri May 25 09:50:04 UTC 2012 x86_64 GNU/Linux
      # INTERNAL ERROR!!! undefined method `[]' for nil:NilClass
      ATTRIBUTOR_EPOCH = ::DateTime.strptime("9/30/2013 8:00 AM", "%m/%d/%Y %H:%M %p")

      def self.native_type
        return ::DateTime
      end

      def self.example
        return ATTRIBUTOR_EPOCH - rand(1000)
      end

      def self.load(value)
        # We assume that if the value is already in the right type, we've decoded it already
        return value if value.is_a?(self.native_type)
        return nil unless value.is_a?(::String)
        # TODO: we should be able to convert not only from String but Time...etc
        # Else, we'll decode it from String.
        begin
          return ::DateTime.parse(value)
        rescue ArgumentError => e
          raise AttributorException.new("#{e.message}: #{value.inspect}")
        end
      end

    end

  end

