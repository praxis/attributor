require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Boolean do

  subject(:type) { Attributor::Boolean }

  context '.valid_type?' do

    context 'for incoming Boolean values' do

      [false, true].each do |value|

        it "returns true for #{value.inspect}" do
          type.valid_type?(value).should be_true
        end

      end

    end

    context 'for incoming non-Boolean values' do

      ['false', 2, 1.0, Class, Object.new].each do |value|

        it "returns false for #{value.inspect}" do
          type.valid_type?(value).should be_false
        end

      end

    end

  end

  context '.example' do
    it "should return a valid Boolean" do
      [true, false].should include type.example
    end
  end

  context '.load' do

    context 'for incoming Boolean false values' do

      [false, 'false', 'FALSE', '0', 0, 'f', 'F'].each do |value|

        it "returns false for #{value.inspect}" do
          type.load(value).should be(false)
        end

      end

    end

    context 'for incoming Boolean false values' do

      [true, 'true', 'TRUE', '1', 1, 't', 'T'].each do |value|

        it "returns true for #{value.inspect}" do
          type.load(value).should be(true)
        end

      end

    end

    it 'returns nil for nil' do
      type.load(nil).should be(nil)
    end

    context 'that are not valid Booleans' do
      let(:context){ ['root','subattr'] }
      ['string', 2, 1.0, Class, Object.new].each do |value|

        it "raises Attributor::CoercionError for #{value.inspect}" do
          expect {
            type.load(value,context)
          }.to raise_error(Attributor::CoercionError, /Error coercing from .+ to Attributor::Boolean.* #{context.join('.')}/)
        end

      end

    end

  end

end


