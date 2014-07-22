require 'tempfile'

module Attributor
  class Tempfile
    include Attributor::Type

    def self.native_type
      return ::Tempfile
    end

    def self.example(context=Attributor::DEFAULT_ROOT_CONTEXT, options:{})
      ::Tempfile.new(Attributor.humanize_context(context))
    end

    def self.dump(value, **opts)
      value.path
    end

    def self.load(value,context=Attributor::DEFAULT_ROOT_CONTEXT, **options)
      # TODO: handle additional cases that make sense
      case value
      when ::String
        name = Attributor.humanize_context(context)

        file = Tempfile.new(name)
        file.write(value)
        file.rewind
        return file
      end

      super
    end

    
  end
end
