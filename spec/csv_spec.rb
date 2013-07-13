require_relative 'spec_helper'
      
describe Attributor::CSV do

  let(:the_name){ 'csv_values' }
  let(:opts) { {} }
  subject { 
    Attributor::CSV.new(the_name, opts)
  }
  its(:native_type) { should == Attributor::Array.native_type }  
  it 'derives from Attributor::Array' do
    ( subject.class < Attributor::Array).should be_true
  end
  it 'has a default empty csv string' do
    Attributor::CSV::DEFAULT_EMPTY_CSV.should == "__none__"
  end 
  
  context 'initializing' do

    context 'not specifying the default_empty_csv string option' do
      let(:opts) { {} }
      it 'should set it to the default (and save it in @empty_csv_string)' do
        subject.empty_csv_string.should == Attributor::CSV::DEFAULT_EMPTY_CSV
      end
    end
    context 'specifying the default_empty_csv string option' do
      let(:opts) { {:empty_csv_string => "none" } }
      it 'should set it to the default' do
        subject.empty_csv_string.should == "none"
      end
    end
    
  end
  
  context 'validating options' do
    
    context 'if an invalid option is passed' do
      it 'raises an error from the superclass ' do
        expect {
          Attributor::CSV.new(the_name, {:not_valid => 'option'})
        }.to raise_error(Exception, /ERROR, unknown option/ )
      end
    end
    context 'when passing an :empty_csv_string that it is not a String' do
      it 'raises an error ' do
        expect {
          Attributor::CSV.new(the_name, {:empty_csv_string => 123 })
        }.to raise_error(Exception, /:empty_csv_string option must be a String/ )
      end
    end
  end
  
  context 'decoding' do
    let(:opts) { {:empty_csv_string => "none" } }
    context 'when passing a String value matching the defined empty csv' do
      it 'decodes to an empty array' do
        subject.decode("none","context").should == {:loaded_value => [], :errors => [] }
      end
    end
    context 'when passing a String value that does not match defined empty csv' do
      it 'decodes to an array with the elements split by commas' do
        subject.decode("a,b,c","context").should == {:loaded_value => ["a","b","c"], :errors => [] }
      end
    end

    context 'when passing an Array already' do
      it 'decodes to the exact same argument and context' do
        subject.decode([1,2],"context").should == {:loaded_value => [1,2], :errors => [] }
      end
    end
  end
end

