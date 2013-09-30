require_relative 'spec_helper'
      
describe Attributor::Ids do

  let(:the_name){ 'ids' }
  let(:opts) { {} }
  subject { 
    Attributor::Ids.new(the_name, opts)
  }
  its(:native_type) { should == Attributor::Array.native_type }  
  it 'derives from Attributor::CSV' do
    ( subject.class < Attributor::CSV).should be_true
  end
  it 'has a default definition to denote an empty csv string' do
    Attributor::Ids::EMPTY_ID_STRING.should == "__multiple_ids__"
  end 
  it 'has a default String type for the ids' do
    Attributor::Ids::DEFAULT_ELEMENT_TYPE.should == Attributor::String
  end
  
  context 'initializing' do

    it 'passes initializes the CSV with the default string for ids' do
      subject.options.should have_key(:empty_csv_string)
      subject.options[:empty_csv_string].should == Attributor::Ids::EMPTY_ID_STRING
    end
    
    context 'passing the appropriate :element_type down to the CSV constructor' do
      context 'when explicitly defined' do
        let(:opts){ {:element_type => Integer} }
        it 'propagates as is' do
          subject.options.should have_key(:element_type)
          subject.options[:element_type].should == Attributor::Integer
        end
      end
      context 'when not explicitly defined' do
        let(:opts) { {} }
        it 'it injects the default element type' do
          subject.options.should have_key(:element_type)
          subject.options[:element_type].should == Attributor::Ids::DEFAULT_ELEMENT_TYPE
        end

      end
    end
  end  
end

