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

  context '.load' do
    let(:chicken) { Chicken.example }
    let(:duck) { Duck.example }
    let(:turkey) { Turkey.example }

    it 'loads' do
      expect(type.load(chicken.dump)).to be_kind_of(Chicken)
      expect(type.load(duck.dump)).to be_kind_of(Duck)
      expect(type.load(turkey.dump)).to be_kind_of(Turkey)
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

  context 'as an attribute in a model' do
    let(:model) { Sandwich }
    subject(:example) { model.example }
    it 'generates an example properly' do
      expect([Chicken, Duck, Turkey]).to include(example.meat.class)
    end
  end
end
