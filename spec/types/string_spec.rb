require_relative '../spec_helper'

describe Attributor::String do

  subject(:type) { Attributor::String }

  context '.native_type' do
    it "should return String" do
      type.native_type.should be(::String)
    end
  end

  context '.example' do
    it "should return a valid String" do
      type.example(:regexp => /\w\d{2,3}/).should be_a(::String)
    end

    it "should return a valid String" do
      type.example.should be_a(::String)
    end
  end

  context '.load' do
    let(:value) { nil }

    context 'for incoming String values' do

      it 'returns the incoming value' do
        ['', 'foo', '0.0', '-1.0', '1.0', '1e-10'].each do |value|
          type.load(value).should be(value)
        end
      end
    end

    context 'for incoming Integer values' do

      context 'with an integer value' do
        let(:value) { 1 }

        it 'raises an error' do
          expect { type.load(value) }.to raise_error(/String cannot load value/)
        end
      end
    end
  end

end

