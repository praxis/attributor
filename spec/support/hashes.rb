class HashWithModel < Attributor::Hash
  keys do
    key :name, String, default: 'Turkey McDucken', description: 'Turducken name', example: Randgen.name
    key :chicken, Chicken
  end
end

class HashWithStrings < Attributor::Hash
  keys do
    key :name, String
    key :something, String
  end
end
