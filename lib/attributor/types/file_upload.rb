module Attributor
  class FileUpload < Attributor::Model
    attributes do
      attribute :name, String
      attribute :filename, String
      attribute :type, String
      attribute :tempfile, Tempfile
      attribute :head, String
    end
  end
end
