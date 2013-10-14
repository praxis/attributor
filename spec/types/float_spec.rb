require_relative '../spec_helper'

describe Attributor::Float do

  subject(:type) { Attributor::Float }

  context '.native_type' do
    its(:native_type) { should be(::Float) }
  end

  context '.example' do
    its(:example) { should be_a(::Float) }
  end

  context '.load' do
    let(:value) { nil }

    context 'for incoming Float values' do

      it 'returns the incoming value' do
        [0.0, -1.0, 1.0, 1e-10].each do |value|
          type.load(value).should be(value)
        end
      end
    end

    context 'for incoming Integer values' do

      context 'with an integer value' do
        let(:value) { 1 }
        it 'decodes it if the Integer represents a Float' do
          type.load(value).should == 1.0
        end
      end
    end

    context 'for incoming String values' do

      context 'that are valid Floats' do
        ['0.0', '-1.0', '1.0', '1e-10'].each do |value|
          it 'decodes it if the String represents a Float' do
            type.load(value).should == Float(value)
          end
        end
      end

      context 'that are valid Integers' do
        let(:value) { '1' }
        it 'decodes it if the String represents an Integer' do
          type.load(value).should == 1.0
        end
      end

      context 'that are not valid Floats' do

        context 'with simple alphanumeric text' do
          let(:value) { 'not a Float' }

          it 'raises an error' do
            expect { type.load(value) }.to raise_error(/invalid value/)
          end
        end

      end

    end
  end
end

