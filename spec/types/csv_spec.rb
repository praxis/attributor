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

end
