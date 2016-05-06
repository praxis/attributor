require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::BigDecimal do
  subject(:type) { Attributor::BigDecimal }

  it 'it is not Dumpable' do
    type.new.is_a?(Attributor::Dumpable).should_not be(true)
  end

  context '.native_type' do
    its(:native_type) { should be(::BigDecimal) }
  end

  context '.example' do
    its(:example) { should be_a(::BigDecimal) }
    it do
      ex = type.example
    end
  end

  context '.load' do
    let(:value) { nil }
    it 'returns nil for nil' do
      type.load(nil).should be(nil)
    end

    context 'for incoming Float values' do
      it 'returns the incoming value' do
        [0.0, -1.0, 1.0, 1e-10, 0.25135].each do |value|
          type.load(value).should eq(value)
        end
      end
    end

    context 'for incoming Integer values' do
      it 'should equal the incoming value' do
        [0, -1, 1].each do |value|
          type.load(value).should eq(value)
        end
      end
    end

    context 'for incoming String values' do
      it 'should equal the value' do
        type.load('0').should eq(0)
        type.load('100').should eq(100)
        type.load('0.1').should eq(0.1)
      end
    end
  end
end
