require 'tempfile'

module Attributor
  class Tempfile
    include Attributor::Type

    def self.native_type
      ::Tempfile
    end

    def self.example(context = Attributor::DEFAULT_ROOT_CONTEXT, options:{})
      file = ::Tempfile.new(Attributor.humanize_context(context))
      file.write /[:sentence:]/.gen
      file.write '.'
      file.rewind
      file
    end

    def self.dump(value, **_opts)
      value && value.read
    end

    def self.load(value, context = Attributor::DEFAULT_ROOT_CONTEXT, **options)
      # TODO: handle additional cases that make sense
      case value
      when ::String
        name = Attributor.humanize_context(context)

        file = ::Tempfile.new(name)
        file.write(value)
        file.rewind
        return file
      end

      super
    end

    def self.family
      String.family
    end
  end
end
