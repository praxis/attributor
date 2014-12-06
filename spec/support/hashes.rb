class HashWithModel < Attributor::Hash
  keys do
    key :name, String, :default => "Turkey McDucken", :description => "Turducken name", :example => /[:name:]/
    key :chicken, Chicken
  end
end

