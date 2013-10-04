require_relative '../spec_helper'

describe Attributor::Struct do

  context '.construct' do

    context 'empty struct' do
      let(:attribute_definition) do
        Proc.new {}
      end

      subject(:new_class) { Attributor::Struct.construct(attribute_definition) }

      it 'returns a new class with no attributes' do
        new_class.should < Attributor::Struct

        attributes = new_class.definition.attributes
        attributes.should be_empty
      end
    end

    context 'simple struct' do
      let(:attribute_definition) do
        Proc.new do
          attribute 'age', Attributor::Integer
        end
      end

      subject(:new_class) { Attributor::Struct.construct(attribute_definition) }

      it 'returns a new class with one attribute' do
        new_class.should < Attributor::Struct

        attributes = new_class.definition.attributes
        attributes.should have_key('age')
      end
    end

    context 'less simple struct' do
      let(:attribute_definition) do
        Proc.new do
          attribute 'age', Attributor::Integer
          attribute 'name', Attributor::String
          attribute 'employed?', Attributor::Boolean
          attribute 'salary', Attributor::Float
          attribute 'hired_at', Attributor::DateTime
        end
      end

      subject(:new_class) { Attributor::Struct.construct(attribute_definition) }

      it 'returns a new class with five attributes' do
        new_class.should < Attributor::Struct

        attributes = new_class.definition.attributes
        attributes.should have_key('age')
        attributes.should have_key('name')
        attributes.should have_key('employed?')
        attributes.should have_key('salary')
        attributes.should have_key('hired_at')
      end
    end

    context 'complex struct containing model' do
      let(:attribute_definition) do
        Proc.new do
          attribute 'pet', ::Chicken
        end
      end

      subject(:new_class) { Attributor::Struct.construct(attribute_definition) }

      it 'returns a new class with attribute attributes' do
        new_class.should < Attributor::Struct

        attributes = new_class.definition.attributes
        attributes.should have_key('pet')
      end
    end

    context 'complex struct containing other struct' do
      let(:attribute_definition) do
        Proc.new do
          Proc.new do
            attribute 'months', Attributor::Integer
          end
        end
      end

      subject(:new_class) { Attributor::Struct.construct(attribute_definition) }

      it 'raises' do
        new_class.should < Attributor::Struct

        # TODO: Fix this to not fail
        expect { attributes = new_class.definition.attributes }.to raise_error(Attributor::AttributorException)
      end
    end
  end
end