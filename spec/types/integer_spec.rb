require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Integer do
  subject(:type) { Attributor::Integer }

  it 'it is not Dumpable' do
    expect(type.new.is_a?(Attributor::Dumpable)).not_to be(true)
  end

  context '.example' do
    context 'when :min and :max are unspecified' do
      context 'valid cases' do
        it "returns an Integer in the range [0,#{Attributor::Integer::EXAMPLE_RANGE}]" do
          20.times do
            value = type.example
            expect(value).to be_a(::Integer)
            expect(value).to be <= Attributor::Integer::EXAMPLE_RANGE
            expect(value).to be >= 0
          end
        end
      end
    end

    context 'when :min is unspecified' do
      context 'valid cases' do
        [5, 100_000_000_000_000_000_000, -100_000_000_000_000_000_000].each do |max|
          it "returns an Integer in the range [,#{max.inspect}]" do
            20.times do
              value = type.example(nil, options: { max: max })
              expect(value).to be_a(::Integer)
              expect(value).to be <= max
              expect(value).to be >= max - Attributor::Integer::EXAMPLE_RANGE
            end
          end
        end
      end

      context 'invalid cases' do
        ['invalid', false].each do |max|
          it "raises for the invalid range [,#{max.inspect}]" do
            expect do
              value = type.example(nil, options: { max: max })
              expect(value).to be_a(::Integer)
            end.to raise_error(Attributor::AttributorException, "Invalid range: [, #{max.inspect}]")
          end
        end
      end
    end

    context 'when :max is unspecified' do
      context 'valid cases' do
        [1, -100_000_000_000_000_000_000, 100_000_000_000_000_000_000].each do |min|
          it "returns an Integer in the range [#{min.inspect},]" do
            20.times do
              value = type.example(nil, options: { min: min })
              expect(value).to be_a(::Integer)
              expect(value).to be <= min + Attributor::Integer::EXAMPLE_RANGE
              expect(value).to be >= min
            end
          end
        end
      end

      context 'invalid cases' do
        ['invalid', false].each do |min|
          it "raises for the invalid range [#{min.inspect},]" do
            expect do
              value = type.example(nil, options: { min: min })
              expect(value).to be_a(::Integer)
            end.to raise_error(Attributor::AttributorException, "Invalid range: [#{min.inspect},]")
          end
        end
      end
    end

    context 'when :min and :max are specified' do
      context 'valid cases' do
        [
          [1, 1],
          [1, 5],
          [-2, -2],
          [-3, 2],
          [-1_000_000_000_000_000, 1_000_000_000_000_000]
        ].each do |min, max|
          it "returns an Integer in the range [#{min.inspect},#{max.inspect}]" do
            20.times do
              value = type.example(nil, options: { max: max, min: min })
              expect(value).to be <= max
              expect(value).to be >= min
            end
          end
        end
      end

      context 'invalid cases' do
        [[1, -1], [1, '5'], ['-2', 4], [false, false], [true, true]].each do |min, max|
          it "raises for the invalid range [#{min.inspect}, #{max.inspect}]" do
            opts = { options: { max: max, min: min } }
            expect do
              type.example(nil, opts)
            end.to raise_error(Attributor::AttributorException, "Invalid range: [#{min.inspect}, #{max.inspect}]")
          end
        end
      end
    end
  end

  context '.load' do
    let(:value) { nil }

    it 'returns nil for nil' do
      expect(type.load(nil)).to be(nil)
    end

    context 'for incoming integer values' do
      let(:value) { 1 }

      it 'returns the incoming value' do
        expect(type.load(value)).to be(value)
      end
    end

    context 'for incoming string values' do
      context 'that are valid integers' do
        let(:value) { '1024' }
        it 'decodes it if the string represents an integer' do
          expect(type.load(value)).to eq 1024
        end
      end

      context 'that are not valid integers' do
        context 'with simple alphanumeric text' do
          let(:value) { 'not an integer' }

          it 'raises an error' do
            expect { type.load(value) }.to raise_error(/invalid value/)
          end
        end

        context 'with a floating point value' do
          let(:value) { '98.76' }
          it 'raises an error' do
            expect { type.load(value) }.to raise_error(/invalid value/)
          end
        end
      end
    end
  end
end
