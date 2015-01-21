# Abstract type for the 'temporal' family

module Attributor
  module Temporal
    extend ActiveSupport::Concern
    include Type

    module ClassMethods
      def native_type
        raise NotImplementedError
      end

      def family
        'temporal'
      end

      def dump(value, **_opts)
        value && value.iso8601
      end

      def json_schema_type
        :string
      end
    end
  end
end
