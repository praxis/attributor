# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Polymorphic do
  subject(:type) do
    Attributor::Polymorphic.on(:type)
  end

  before do
    type.given :chicken, Chicken
    type.given :duck, Duck
    type.given :turkey, Turkey
  end

  its(:discriminator) { should be :type }
  its(:types) { should eq(chicken: Chicken, duck: Duck, turkey: Turkey) }
  its(:native_type) { should be type }

  context '.load' do
    let(:chicken) { Chicken.example }
    let(:duck) { Duck.example }
    let(:turkey) { Turkey.example }

    it 'loads' do
      expect(type.load(chicken.dump)).to be_kind_of(Chicken)
      expect(type.load(duck.dump)).to be_kind_of(Duck)
      expect(type.load(turkey.dump)).to be_kind_of(Turkey)
    end

    it 'loads a hash with string keys' do
      data = { 'type' => :chicken }
      expect(type.load(data)).to be_kind_of(Chicken)
    end

    it 'raises a LoadError if the discriminator value is unknown' do
      data = { type: :turducken }
      expect { type.load(data) }.to raise_error(Attributor::LoadError)
    end

    it 'raises a LoadError if the discriminator value is missing' do
      data = { id: 1 }
      expect { type.load(data) }.to raise_error(Attributor::LoadError)
    end

    context 'for a type with a string discriminator' do
      subject(:string_type) do
        Attributor::Polymorphic.on('type')
      end
      it 'loads a hash with symbol keys' do
        data = { 'type' => :chicken }
        expect(type.load(data)).to be_kind_of(Chicken)
      end
    end
  end

  context '.dump' do
    context 'when used in a model' do
      let(:example) { Sandwich.example }
      subject(:dumped) { example.dump }

      it 'properly dumps the attribute' do
        expect(dumped[:meat]).to eq example.meat.dump
      end
    end
  end

  context '.valid_type?' do
    it 'is true for instances of possible types' do
      [Chicken, Duck, Turkey].each do |bird_type|
        example = bird_type.example
        expect(type.valid_type?(example)).to be_truthy
      end
    end
    it 'is false for other model types' do
      [Address, Person].each do |other_type|
        example = other_type.example
        expect(type.valid_type?(example)).to be_falsey
      end
    end
  end

  context '.example' do
    subject(:example) { type.example }
    it do
      expect([Chicken, Duck, Turkey]).to include(type.example.class)
    end
  end

  context '.describe' do
    let(:example) { nil }
    subject(:description) { type.describe(example: example) }

    its([:discriminator]) { should eq :type }
    context 'types' do
      subject(:types) { description[:types] }
      its(:keys) { should eq type.types.keys }
      it do
        expect(types[:chicken]).to eq(type: Chicken.describe(true))
        expect(types[:turkey]).to eq(type: Turkey.describe(true))
        expect(types[:duck]).to eq(type: Duck.describe(true))
      end
    end

    context 'in a Model' do
      subject(:description) { Sandwich.describe[:attributes][:meat][:type] }
      its([:discriminator]) { should eq :type }
      context 'types' do
        subject(:types) { description[:types] }
        its(:keys) { should match_array %i[chicken turkey duck] }
        it do
          expect(types[:chicken]).to eq(type: Chicken.describe(true))
          expect(types[:turkey]).to eq(type: Turkey.describe(true))
          expect(types[:duck]).to eq(type: Duck.describe(true))
        end
      end
    end
  end

  context 'as an attribute in a model' do
    let(:model) { Sandwich }
    subject(:example) { model.example }
    it 'generates an example properly' do
      expect([Chicken, Duck, Turkey]).to include(example.meat.class)
    end

    context 'loading' do
      [Chicken, Duck, Turkey].each do |meat_class|
        it "loads #{meat_class}" do
          data = { meat: meat_class.example.dump }
          expect(Sandwich.load(data).meat).to be_kind_of(meat_class)
        end
      end
    end
  end
end
