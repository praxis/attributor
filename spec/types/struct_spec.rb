require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Struct do
  context '.definition for a Struct with no sub-attributes' do
    subject { Attributor::Struct }
    it 'raises an error' do
      expect do
        subject.definition
      end.to raise_error(Attributor::AttributorException, 'Can not use a pure Struct without defining sub-attributes')
    end
  end
  context '.construct' do
    context 'empty struct' do
      let(:attribute_definition) do
        proc {}
      end

      subject(:empty_struct) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with no attributes' do
        expect(empty_struct).to be_subclass_of Attributor::Struct

        attributes = empty_struct.attributes
        expect(attributes).to be_empty
      end
    end

    context 'simple struct' do
      let(:attribute_definition) do
        proc do
          attribute :age, Attributor::Integer
        end
      end

      subject(:simple_struct) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with one attribute' do
        expect(simple_struct).to be_subclass_of Attributor::Struct

        attributes = simple_struct.attributes
        expect(attributes).to have_key :age
      end
    end

    context 'less simple struct' do
      let(:attribute_definition) do
        proc do
          attribute :age, Attributor::Integer
          attribute :name, Attributor::String
          attribute :employed?, Attributor::Boolean
          attribute :salary, Attributor::Float
          attribute :hired_at, Attributor::DateTime
        end
      end

      subject(:large_struct) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with five attributes' do
        expect(large_struct).to be_subclass_of Attributor::Struct

        attributes = large_struct.attributes
        expect(attributes).to have_key :age
        expect(attributes).to have_key :name
        expect(attributes).to have_key :employed?
        expect(attributes).to have_key :salary
        expect(attributes).to have_key :hired_at
      end
    end

    context 'complex struct containing model' do
      let(:attribute_definition) do
        proc do
          attribute :pet, ::Chicken
        end
      end

      subject(:struct_of_models) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with a model attribute' do
        expect(struct_of_models).to be_subclass_of Attributor::Struct

        attributes = struct_of_models.attributes
        expect(attributes).to have_key :pet
      end
    end

    context 'complex struct containing named struct' do
      let(:attribute_definition) do
        proc do
          attribute :stats, Attributor::Struct do
            attribute :months, Attributor::Integer
            attribute :days, Attributor::Integer
          end
        end
      end

      subject(:struct_of_structs) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with a named struct attribute' do
        expect(struct_of_structs).to be_subclass_of Attributor::Struct

        attributes = struct_of_structs.attributes
        expect(attributes).to have_key :stats

        stats = attributes[:stats].attributes
        expect(stats).to have_key :months
        expect(stats).to have_key :days
      end
    end

    context 'complex struct containing multi-level recursive structs' do
      let(:attribute_definition) do
        proc do
          attribute :arthropods, Attributor::Struct do
            attribute :insects, Attributor::Struct do
              attribute :ants, Attributor::Struct do
                attribute :name, Attributor::String
                attribute :age, Attributor::Integer
                attribute :weight, Attributor::Float
              end
            end
          end
        end
      end

      subject(:multi_level_struct_of_structs) { Attributor::Struct.construct(attribute_definition) }

      it 'constructs a struct with multiple levels of named struct attributes' do
        expect(multi_level_struct_of_structs).to be_subclass_of Attributor::Struct

        root = multi_level_struct_of_structs.attributes
        expect(root).to have_key :arthropods

        arthropods = root[:arthropods].attributes
        expect(arthropods).to have_key :insects

        insects = arthropods[:insects].attributes
        expect(insects).to have_key :ants

        ants = insects[:ants].attributes
        expect(ants).to have_key :name
        expect(ants).to have_key :age
        expect(ants).to have_key :weight
      end
    end

    context 'with a reference' do
      let(:reference) { Chicken }
      let(:attribute_definition) do
        proc do
        end
      end
      subject(:struct) { Attributor::Struct.construct(attribute_definition, options) }

      context 'with new type-level options' do
        let(:options) { { reference: reference } }
        its(:options) { should have_key(:identity) }
        it 'inherits from the reference' do
          expect(struct.options[:identity]).to eq(reference.options[:identity])
        end
        it 'does not raise an error when used in an attribute' do
          expect do
            Attributor::Attribute.new(struct)
          end.to_not raise_error
        end
      end

      context 'with existing type-level options' do
        let(:options) { { reference: reference, identity: :name } }
        its(:options) { should have_key(:identity) }
        it 'does not override from the reference' do
          expect(struct.options[:identity]).to eq(:name)
        end
        it 'does not raise an error when used in an attribute' do
          expect do
            Attributor::Attribute.new(struct)
          end.to_not raise_error
        end
      end
    end
  end
end
