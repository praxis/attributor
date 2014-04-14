module Attributor

  class CSV < Collection

    def self.decode_string(value,context)
      value.split(',')
    end

  end
end
