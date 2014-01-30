require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Attributor::Hash do

  subject(:type) { Attributor::Hash }

  context '.native_type' do
    it 'should return Hash' do
      type.native_type.should be(::Hash)
    end
  end

  context '.example' do
    it 'should return an empty Hash' do
      type.example.should eq(Hash.new)
    end
  end

  context '.load' do
    let(:value) { {one: 'two', three: 4} }

    context 'for a hash' do

      it 'returns the hash' do
        type.load(value).should be(value)
      end
    end

  end

  context 'in an Attribute' do
    let(:options) { {} }
    subject(:attribute) { Attributor::Attribute.new(Attributor::Hash, options)}

    context 'with an example option that is a proc' do
      let(:example_hash) { {:key => "value"} }
      let(:options) { { example: proc { example_hash } } }
      it 'uses the hash' do
        attribute.example.should be(example_hash)
      end
    end
  end
end

