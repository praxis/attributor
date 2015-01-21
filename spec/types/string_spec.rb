require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::String do
  subject(:type) { Attributor::String }

  it 'it is not Dumpable' do
    expect(type.new.is_a?(Attributor::Dumpable)).not_to be(true)
  end

  context '.native_type' do
    it 'returns String' do
      expect(type.native_type).to be(::String)
    end
  end

  context '.example' do
    it 'should return a valid String' do
      expect(type.example(options: { regexp: /\w\d{2,3}/ })).to be_a(::String)
    end

    it 'should return a valid String' do
      expect(type.example).to be_a(::String)
    end

    it 'handles regexps that Randexp can not (#72)' do
      regex = /\w+(,\w+)*/
      expect do
        val = Attributor::String.example(options: { regexp: regex })
        expect(val).to be_a(::String)
        expect(val).to match(/Failed to generate.+is too vague/)
      end.to_not raise_error
    end
  end

  context '.load' do
    let(:value) { nil }

    it 'returns nil for nil' do
      expect(type.load(nil)).to be(nil)
    end

    context 'for incoming String values' do
      it 'returns the incoming value' do
        ['', 'foo', '0.0', '-1.0', '1.0', '1e-10', 1].each do |value|
          expect(type.load(value)).to eq(String(value))
        end
      end
    end
  end

  context 'for incoming Symbol values' do
    let(:value) { :something }
    it 'returns the stringified-value' do
      expect(type.load(value)).to eq value.to_s
    end
  end

  context 'for Enumerable values' do
    let(:value) { [1] }

    it 'raises IncompatibleTypeError' do
      expect do
        type.load(value)
      end.to raise_error(Attributor::IncompatibleTypeError)
    end
  end

  context '.as_json_schema' do
    subject(:js){ type.as_json_schema(attribute_options: { regexp: /^Foobar$/ }) }
    it 'adds the right attributes' do
      expect(js.keys).to include(:type, :'x-type_name')
      expect(js[:type]).to eq(:string)
      expect(js[:'x-type_name']).to eq('String')
      expect(js[:pattern]).to eq('^Foobar$')
    end
  end
end
