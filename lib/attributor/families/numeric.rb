# Abstract type for the 'numeric' family

module Attributor
  module Numeric
    extend ActiveSupport::Concern
    include Type

    module ClassMethods
      
      def native_type
        raise NotImplementedError
      end

      def family
        'numeric'
      end

      def as_json_schema( shallow: false, example: nil, attribute_options: {} )
        h = super
        opts = ( self.respond_to?(:options) ) ? self.options.merge( attribute_options ) : attribute_options
        h[:minimum] = opts[:min] if opts[:min]
        h[:maximum] = opts[:max] if opts[:max]
        # We're not explicitly setting false to exclusiveMinimum and exclusiveMaximum (as that's the default)
        h
      end
    end
  end
end
