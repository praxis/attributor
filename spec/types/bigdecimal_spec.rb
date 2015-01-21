require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::BigDecimal do
  subject(:type) { Attributor::BigDecimal }

  it 'it is not Dumpable' do
    expect(type.new.is_a?(Attributor::Dumpable)).not_to be(true)
  end

  context '.native_type' do
    its(:native_type) { should be(::BigDecimal) }
  end

  context '.example' do
    its(:example) { should be_a(::BigDecimal) }
  end

  context '.load' do
    let(:value) { nil }
    it 'returns nil for nil' do
      expect(type.load(nil)).to be(nil)
    end

    context 'for incoming Float values' do
      it 'returns the incoming value' do
        [0.0, -1.0, 1.0, 1e-10, 0.25135].each do |value|
          expect(type.load(value)).to eq(value)
        end
      end
    end

    context 'for incoming Integer values' do
      it 'should equal the incoming value' do
        [0, -1, 1].each do |value|
          expect(type.load(value)).to eq(value)
        end
      end
    end

    context 'for incoming String values' do
      it 'should equal the value' do
        expect(type.load('0')).to eq(0)
        expect(type.load('100')).to eq(100)
        expect(type.load('0.1')).to eq(0.1)
      end
    end
  end
  context '.as_json_schema' do
    subject(:js){ type.as_json_schema }
    it 'adds the right attributes' do
      expect(js.keys).to include(:type, :'x-type_name')
      expect(js[:type]).to eq(:number)
      expect(js[:'x-type_name']).to eq('BigDecimal')
    end
  end
end
