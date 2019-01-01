# frozen_string_literal: true

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::CSV do
  subject!(:csv) { Attributor::CSV.of(Integer) }

  context '.load' do
    let!(:array) { (1..10).to_a }
    let!(:value) { array.join(',') }

    it 'parses the value and returns an array with the right types' do
      expect(csv.load(value)).to match_array array
    end
  end

  context '.example' do
    let!(:example) { csv.example }
    let!(:loaded_example) { csv.load(example) }

    it 'generates a String example' do
      expect(example).to be_a(String)
    end

    it 'generates a comma-separated list of Integer values' do
      expect(loaded_example).to be_a(csv)
      expect(loaded_example.size).to be > 1
      loaded_example.each { |e| expect(e).to be_a(Integer) }
    end
  end

  context '.dump' do
    let!(:int_vals) { [1, 2, 3] }
    let!(:str_vals) { (0..2).collect { /\w+/.gen } }

    it 'dumps a String value' do
      expect(csv.dump(int_vals)).to be_a(String)
    end

    it 'dumps a comma-separated list of Integers' do
      expect(csv.dump(int_vals)).to eq(int_vals.join(','))
    end

    it 'dumps non-Integer values also' do
      expect(csv.dump(str_vals)).to eq(str_vals.join(','))
    end

    it 'dumps nil values as nil' do
      expect(csv.dump(nil)).to eq(nil)
    end
  end

  context '.describe' do
    let(:example) { csv.example }
    subject(:described) { csv.describe(example: example) }
    it 'adds a string example if an example is passed' do
      expect(described).to have_key(:example)
      expect(described[:example]).to eq(csv.dump(example))
    end
    it 'ensures no member_attribute key exists from underlying Collection' do
      expect(described).not_to have_key(:member_attribute)
    end
  end
end
