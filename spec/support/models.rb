class Chicken < Attributor::Model
  attributes(identity: :email) do
    attribute :name, Attributor::String, example: proc { Faker::Name.first_name }
    attribute :age, Attributor::Integer, default: 1, min: 0, max: 120, description: 'The age of the chicken'
    attribute :email, Attributor::String, example: proc { "#{Faker::Name.first_name.downcase}@#{Faker::Lorem.word.downcase}.example.org" }, regexp: /@/, description: 'The email address of the chicken'
    attribute :angry, Attributor::Boolean, example: 'true', description: 'Angry bird?'
    attribute :weight, Attributor::Float, example: proc { Faker::Number.number(digits: 3) }, description: 'The weight of the chicken'
    attribute :type, Attributor::Symbol, values: [:chicken]
  end
end

class Duck < Attributor::Model
  attributes do
    attribute :age, Attributor::Integer
    attribute :name, Attributor::String
    attribute :email, Attributor::String
    attribute :angry, Attributor::Boolean, default: true, example: proc { [true, false].sample }, description: 'Angry bird?'
    attribute :weight, Attributor::Float, example: proc { Faker::Number.number(digits: 3).to_f }, description: 'The weight of the duck'
    attribute :type, Attributor::Symbol, values: [:duck]
  end
end

class Turkey < Attributor::Model
  attributes do
    attribute :age, Integer, default: 1, min: 0, max: 120, description: 'The age of the turkey'
    attribute :name, String, description: 'name of the turkey', example: proc { Faker::Name.name } # , :default => "Providencia Zboncak"
    attribute :email, String, example: proc { "#{Faker::Name.first_name.downcase}@example.org" }, regexp: /@/, description: 'The email address of the turkey'
    attribute :weight, Attributor::Float, example: proc { Faker::Number.number(digits: 2).to_f }, max: 100.0, description: 'The weight of the turkey'
    attribute :type, Attributor::Symbol, values: [:turkey]
  end
end

class Turducken < Attributor::Model
  attributes do
    attribute :name, String, default: 'Turkey McDucken', description: 'Turducken name', example: proc { Faker::Name.first_name }
    attribute :chicken, Chicken
    attribute :duck, Duck
    attribute :turkey, Turkey, description: 'The turkey'
  end
end

# http://en.wikipedia.org/wiki/Cormorant

class Cormorant < Attributor::Model
  attributes do
    attribute :name, String, description: 'Name of the Cormorant', example: proc { Faker::Name.name }
    attribute :timestamps do
      attribute :born_at, DateTime
      attribute :died_at, DateTime, example: proc { |timestamps| timestamps.born_at + 10 }
    end

    # This will be a collection of arbitrary Ruby Objects
    attribute :all_the_fish, Attributor::Collection, description: 'All kinds of fish for feeding the babies'

    # This will be a collection of Cormorants (note, this relationship is circular)
    attribute :neighbors, Attributor::Collection.of(Cormorant), member_options: { null: false }, description: 'Neighbor cormorants', null: false

    # This will be a collection of instances of an anonymous Struct class, each having two well-defined attributes

    attribute :babies, Attributor::Collection.of(Attributor::Struct), description: 'All the babies', member_options: { identity: :name } do
      attribute :name, Attributor::String, example: proc { Faker::Name.name }, description: 'The name of the baby cormorant', required: true
      attribute :months, Attributor::Integer, default: 0, min: 0, description: 'The age in months of the baby cormorant'
      attribute :weight, Attributor::Float, example:  proc { Faker::Number.number(digits: 2) }, description: 'The weight in kg of the baby cormorant'
    end
  end
end

class Person < Attributor::Model
  attributes do
    attribute :name, String, example: proc { Faker::Name.first_name }
    attribute :title, String, values: %w[Mr Mrs Ms Dr]
    attribute :okay, Attributor::Boolean, values: [true]
    attribute :address, Address, example: proc { |person, context| Address.example(context, person: person) }
  end
end

class Address < Attributor::Model
  attributes do
    attribute :name, String, example: /\w+/, null: true
    attribute :state, String, values: %w[OR CA], null: false
    attribute :person, Person, example: proc { |address, context| Person.example(context, address: address) }
    attribute :substruct, reference: Address, null: false do
      attribute :state, Struct do # redefine state as a Struct
        attribute :foo, Integer, default: 1
      end
    end
    requires :name
  end
end

class Post < Attributor::Model
  attributes do
    attribute :title, String
    attribute :tags, Attributor::Collection.of(String)
  end
end
