require_relative '../spec_helper'

describe Attributor::Integer do

  subject(:type) { Attributor::Integer }

  context '.example' do

    context 'when :min and :max are unspecified' do
      context 'valid cases' do
        it "returns an Integer in the range [0,#{Attributor::Integer::EXAMPLE_RANGE}]" do
          20.times do
            value = type.example
            value.should be_a(::Integer)
            value.should <= Attributor::Integer::EXAMPLE_RANGE
            value.should >= 0
          end
        end
      end
    end

    context 'when :min is unspecified' do
      context 'valid cases' do
        [5, 100000000000000000000, -100000000000000000000].each do |max|
          it "returns an Integer in the range [,#{max.inspect}]" do
            20.times do
              value = type.example(:max => max)
              value.should be_a(::Integer)
              value.should <= max
              value.should >= max - Attributor::Integer::EXAMPLE_RANGE
            end
          end
        end
      end

      context 'invalid cases' do
        ['invalid', false].each do |max|
          it "raises for the invalid range [,#{max.inspect}]" do
            expect {
              value = type.example(:max => max)
              value.should be_a(::Integer)
            }.to raise_error(Attributor::AttributorException, "Invalid range: [, #{max.inspect}]")
          end
        end
      end
    end

    context 'when :max is unspecified' do
      context 'valid cases' do
        [1, -100000000000000000000, 100000000000000000000].each do |min|
          it "returns an Integer in the range [#{min.inspect},]" do
            20.times do
              value = type.example(:min => min)
              value.should be_a(::Integer)
              value.should <= min + Attributor::Integer::EXAMPLE_RANGE
              value.should >= min
            end
          end
        end
      end

      context 'invalid cases' do
        ['invalid', false].each do |min|
          it "raises for the invalid range [#{min.inspect},]" do
            expect {
              value = type.example(:min => min)
              value.should be_a(::Integer)
            }.to raise_error(Attributor::AttributorException, "Invalid range: [#{min.inspect},]")
          end
        end
      end
    end

    context 'when :min and :max are specified' do
      context 'valid cases' do
        [
          [1,1],
          [1,5],
          [-2,-2],
          [-3,2],
          [-1000000000000000,1000000000000000]
        ].each do |min, max|
          it "returns an Integer in the range [#{min.inspect},#{max.inspect}]" do
            20.times do
              value = type.example(:min => min, :max => max)
              value.should <= max
              value.should >= min
            end
          end
        end
      end

      context 'invalid cases' do
        [[1,-1], [1,"5"], ["-2",4], [false, false], [true, true]].each do |min, max|
          it "raises for the invalid range [#{min.inspect}, #{max.inspect}]" do
            opts = {:min => min, :max => max}
            expect {
              type.example(opts)
            }.to raise_error(Attributor::AttributorException, "Invalid range: [#{min.inspect}, #{max.inspect}]")
          end
        end
      end

    end
  end

  context '.load' do
    let(:value) { nil }


    context 'for incoming integer values' do
      let(:value) { 1 }

      it 'returns the incoming value' do
        type.load(value).should be(value)
      end
    end

    context 'for incoming string values' do


      context 'that are valid integers' do
        let(:value) { '1024' }
        it 'decodes it if the string represents an integer' do
          type.load(value).should == 1024
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

