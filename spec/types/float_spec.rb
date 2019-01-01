# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Float do
  subject(:type) { Attributor::Float }

  it 'it is not Dumpable' do
    expect(type.new.is_a?(Attributor::Dumpable)).not_to be(true)
  end

  context '.native_type' do
    its(:native_type) { should be(::Float) }
  end

  context '.example' do
    its(:example) { should be_a(::Float) }

    context 'with options' do
      let(:min) { 1 }
      let(:max) { 2 }

      subject(:examples) { (0..100).collect { type.example(options: { min: min, max: max }) } }

      its(:min) { should be > min }
      its(:max) { should be < max }
    end
  end

  context '.load' do
    let(:value) { nil }

    it 'returns nil for nil' do
      expect(type.load(nil)).to be(nil)
    end

    context 'for incoming Float values' do
      it 'returns the incoming value' do
        [0.0, -1.0, 1.0, 1e-10].each do |value|
          expect(type.load(value)).to be(value)
        end
      end
    end

    context 'for incoming Integer values' do
      context 'with an integer value' do
        let(:value) { 1 }
        it 'decodes it if the Integer represents a Float' do
          expect(type.load(value)).to eq 1.0
        end
      end
    end

    context 'for incoming String values' do
      context 'that are valid Floats' do
        ['0.0', '-1.0', '1.0', '1e-10'].each do |value|
          it 'decodes it if the String represents a Float' do
            expect(type.load(value)).to eq Float(value)
          end
        end
      end

      context 'that are valid Integers' do
        let(:value) { '1' }
        it 'decodes it if the String represents an Integer' do
          expect(type.load(value)).to eq 1.0
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
