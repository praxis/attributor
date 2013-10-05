require_relative '../spec_helper'

describe Attributor::Struct do

  context '.construct' do

    context 'empty struct' do
      let(:attribute_definition) do
        Proc.new {}
      end

      subject(:empty_struct) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with no attributes' do
        empty_struct.should < Attributor::Struct

        attributes = empty_struct.definition.attributes
        attributes.should be_empty
      end
    end

    context 'simple struct' do
      let(:attribute_definition) do
        Proc.new do
          attribute 'age', Attributor::Integer
        end
      end

      subject(:simple_struct) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with one attribute' do
        simple_struct.should < Attributor::Struct

        attributes = simple_struct.definition.attributes
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

      subject(:large_struct) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with five attributes' do
        large_struct.should < Attributor::Struct

        attributes = large_struct.definition.attributes
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

      subject(:struct_of_models) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with a model attribute' do
        struct_of_models.should < Attributor::Struct

        attributes = struct_of_models.definition.attributes
        attributes.should have_key('pet')
      end
    end

    context 'complex struct containing named struct' do
      let(:attribute_definition) do
        Proc.new do
          attribute 'stats', Attributor::Struct do
            attribute 'months', Attributor::Integer
            attribute 'days', Attributor::Integer
          end
        end
      end

      subject(:struct_of_structs) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with a named struct attribute' do
        struct_of_structs.should < Attributor::Struct

        attributes = struct_of_structs.definition.attributes
        attributes.should have_key('stats')

        stats = attributes['stats'].attributes
        stats.should have_key('months')
        stats.should have_key('days')
      end
    end

    context 'complex struct containing multi-level recursive structs' do
      let(:attribute_definition) do
        Proc.new do
          attribute 'arthropods', Attributor::Struct do
            attribute 'insects', Attributor::Struct do
              attribute 'ants', Attributor::Struct do
                attribute 'name', Attributor::String
                attribute 'age', Attributor::Integer
                attribute 'weight', Attributor::Float
              end
            end
          end
        end
      end

      subject(:multi_level_struct_of_structs) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with multiple levels of named struct attributes' do
        multi_level_struct_of_structs.should < Attributor::Struct

        root = multi_level_struct_of_structs.definition.attributes
        root.should have_key('arthropods')

        arthropods = root['arthropods'].attributes
        arthropods.should have_key('insects')

        insects = arthropods['insects'].attributes
        insects.should have_key('ants')

        ants = insects['ants'].attributes
        ants.should have_key('name')
        ants.should have_key('age')
        ants.should have_key('weight')
      end
    end
  end
end