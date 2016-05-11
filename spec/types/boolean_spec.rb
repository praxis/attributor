require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Boolean do
  subject(:type) { Attributor::Boolean }

  it 'it is not Dumpable' do
    expect(type.new.is_a?(Attributor::Dumpable)).not_to be(true)
  end

  context '.valid_type?' do
    context 'for incoming Boolean values' do
      [false, true].each do |value|
        it "returns true for #{value.inspect}" do
          expect(type.valid_type?(value)).to be_truthy
        end
      end
    end

    context 'for incoming non-Boolean values' do
      ['false', 2, 1.0, Class, Object.new].each do |value|
        it "returns false for #{value.inspect}" do
          expect(type.valid_type?(value)).to be_falsey
        end
      end
    end
  end

  context '.example' do
    it 'should return a valid Boolean' do
      expect([true, false]).to include type.example
    end
  end

  context '.load' do
    context 'for incoming Boolean false values' do
      [false, 'false', 'FALSE', '0', 0, 'f', 'F'].each do |value|
        it "returns false for #{value.inspect}" do
          expect(type.load(value)).to be(false)
        end
      end
    end

    context 'for incoming Boolean false values' do
      [true, 'true', 'TRUE', '1', 1, 't', 'T'].each do |value|
        it "returns true for #{value.inspect}" do
          expect(type.load(value)).to be(true)
        end
      end
    end

    it 'returns nil for nil' do
      expect(type.load(nil)).to be(nil)
    end

    context 'that are not valid Booleans' do
      let(:context) { %w(root subattr) }
      ['string', 2, 1.0, Class, Object.new].each do |value|
        it "raises Attributor::CoercionError for #{value.inspect}" do
          expect do
            type.load(value, context)
          end.to raise_error(Attributor::CoercionError, /Error coercing from .+ to Attributor::Boolean.* #{context.join('.')}/)
        end
      end
    end
  end
end
