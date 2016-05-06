require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::CSV do
  subject!(:csv) { Attributor::CSV.of(Integer) }

  context '.load' do
    let!(:array) { (1..10).to_a }
    let!(:value) { array.join(',') }

    it 'parses the value and returns an array with the right types' do
      csv.load(value).should =~ array
    end
  end

  context '.example' do
    let!(:example) { csv.example }
    let!(:loaded_example) { csv.load(example) }

    it 'generates a String example' do
      example.should be_a(String)
    end

    it 'generates a comma-separated list of Integer values' do
      loaded_example.should be_a(csv)
      loaded_example.size.should be > 1
      loaded_example.each { |e| e.should be_a(Integer) }
    end
  end

  context '.dump' do
    let!(:int_vals) { [1, 2, 3] }
    let!(:str_vals) { (0..2).collect { /\w+/.gen } }

    it 'dumps a String value' do
      csv.dump(int_vals).should be_a(String)
    end

    it 'dumps a comma-separated list of Integers' do
      csv.dump(int_vals).should eq(int_vals.join(','))
    end

    it 'dumps non-Integer values also' do
      csv.dump(str_vals).should eq(str_vals.join(','))
    end

    it 'dumps nil values as nil' do
      csv.dump(nil).should eq(nil)
    end
  end

  context '.describe' do
    let(:example) { csv.example }
    subject(:described) { csv.describe(example: example) }
    it 'adds a string example if an example is passed' do
      described.should have_key(:example)
      described[:example].should eq(csv.dump(example))
    end
    it 'ensures no member_attribute key exists from underlying Collection' do
      described.should_not have_key(:member_attribute)
    end
  end
end
