class Chicken
  include Attributor::Model
  attributes(:identity => :email) do
    attribute 'age', Integer, :default => 1, :min => 0, :max => 120, :description => "The age of the chicken"
    attribute 'email', String, :example => /[:email:]/, :regexp => /@/, :description => "The email address of the chichen"
  end
end


class Duck
  include Attributor::Model
  attributes do
    attribute 'age', Integer, :required_if => {"name" => "Daffy" }
    attribute 'name', String 
    attribute 'email', String, :required_if => "name"
  end
end


class Turkey
  include Attributor::Model
  attributes(:identity => :email) do
    attribute 'age', Integer, :default => 1, :min => 0, :max => 120, :description => "The age of the chicken"
    attribute 'email', String, :example => /[:email:]/, :regexp => /@/, :description => "The email address of the chichen"
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


