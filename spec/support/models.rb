class Chicken
  include Attributor::Model
  attributes(:identity => :email) do
    attribute 'age', Attributor::Integer, :default => 1, :min => 0, :max => 120, :description => "The age of the chicken"
    attribute 'email', Attributor::String, :example => /[:email:]/, :regexp => /@/, :description => "The email address of the chicken"
    attribute 'angry', Attributor::Boolean, :example => "true", :description => "Angry bird?"
    attribute 'weight', Attributor::Float, :example => /\d{1,2}\.\d/, :description => "The weight of the chicken"
  end
end


class Duck
  include Attributor::Model
  attributes do
    attribute 'age', Attributor::Integer, :required_if => {"name" => "Daffy" }
    attribute 'name', Attributor::String
    attribute 'email', Attributor::String, :required_if => "name"
    attribute 'angry', Attributor::Boolean, :default => true, :example => /true|false/, :description => "Angry bird?"
    attribute 'weight', Attributor::Float, :example => /\d{1,2}\.\d/, :description => "The weight of the duck"
  end
end


class Turkey
  include Attributor::Model
  attributes(:identity => :email) do
    attribute 'age', Attributor::Integer, :default => 1, :min => 0, :max => 120, :description => "The age of the turkey"
    attribute 'email', Attributor::String, :example => /[:email:]/, :regexp => /@/, :description => "The email address of the turkey"
    attribute 'weight', Attributor::Float, :example => /\d{1,2}\.\d/, :max => 86.7, :description => "The weight of the turkey"
  end
end


class Turducken
  include Attributor::Model
  attributes do
    attribute 'chicken', Chicken
    attribute 'duck', Duck
    attribute 'turkey', Turkey
  end
end


