require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::CSV do

  subject!(:csv) { Attributor::CSV.of(Integer) }

  context '.load' do
    let!(:array) { (1..10).to_a }
    let!(:value) { array.join(',') }

    it 'parses the value and returns an array with the right types' do
      csv.load(value).should eq(array)
    end

  end

  context '.example' do
    let!(:example) { csv.example }
    let!(:loaded_example) { csv.load(example) }

    it 'generates a String example' do
      example.should be_a(String)
    end

    it 'generates a comma-separated list of Integer values' do
      loaded_example.should be_a(Array)
      loaded_example.size.should be > 1
      loaded_example.each { |e| e.should be_a(Integer) }
    end
  end

end
