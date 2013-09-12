require_relative '../spec_helper'

describe Attributor::Struct do

  let(:attribute_definition) do
    Proc.new do
      attribute 'id', Integer
      attribute 'name', String
    end
  end


  context '.construct' do
    subject(:new_class) { Attributor::Struct.construct(attribute_definition) }

    it 'returns a new class with the given attributes' do
      new_class.should < Attributor::Struct

      attributes = new_class.definition.attributes
      attributes.should have_key('id')
      attributes.should have_key('name')
    end

  end

end