# frozen_string_literal: true

class Sandwich < Attributor::Model
  attributes do
    attribute :name, String
    attribute :meat, Attributor::Polymorphic.on(:type) do
      given :chicken, Chicken
      given :turkey, Turkey
      given :duck, Duck
    end
  end
end
