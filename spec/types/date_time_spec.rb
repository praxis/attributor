require_relative '../spec_helper'

describe Attributor::Boolean do

  subject(:type) { Attributor::Boolean }

  context '.native_type' do
    it "should return TrueClass" do
      type.native_type.should be(TrueClass)
    end
  end

  context '.load' do

    context 'for incoming Boolean false values' do

      [false, 'false', 'FALSE', '0', 0, 'f', 'F'].each do |value|

        it "returns false for #{value.inspect}" do
          type.load(value).should be(false)
        end

        it "returns native_type TrueClass for #{value.inspect}" do
          type.load(value).should be_a(type.native_type)
        end

      end

    end

    context 'for incoming Boolean false values' do

      [true, 'true', 'TRUE', '1', 1, 't', 'T'].each do |value|

        it "returns true for #{value.inspect}" do
          type.load(value).should be(true)
        end

        it "returns native_type TrueClass for #{value.inspect}" do
          type.load(value).should be_a(type.native_type)
        end

      end

    end

    context 'that are not valid Booleans' do

      ['string', 2, 1.0, Class, Object.new,].each do |value|

        it "raises Attributor::AttributorException for #{value.inspect}" do
          expect {
            type.load(value)
          }.to raise_error(Attributor::AttributorException, "Cannot coerce '#{value.inspect}' into Boolean type")
        end

      end

    end

  end

end


