class PositiveIntegerType < Attributor::Integer

  def self.options
    { min: 0 }
  end
  
end