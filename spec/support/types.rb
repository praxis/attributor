class AttributeType
  include Attributor::Type
  def self.native_type
    ::String
  end
end


class IntegerAttributeType
  include Attributor::Type
  def self.native_type
    ::Integer
  end

  def self.load(value)
    value.to_i
  end

end


