require_relative 'spec_helper'
      
describe Attributor::Boolean do
  
  let(:the_name){ 'bool_attr' }
  let(:opts) { {} }
  subject { 
    Attributor::Boolean.new(the_name, opts)
  }
  its(:native_type) { should == ::Boolean }
  
  its(:supported_options_for_type) { should == [] }
  
  context 'decode' do

    context 'for incoming boolean values' do
      it 'simply loads the value straight (for true)' do
        incoming_val=loaded_val=true
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it 'simply loads the value straight (for false)' do
        incoming_val=loaded_val=false
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
    end
    
    context 'for incoming strings' do
      it 'loads "true" as true' do
        incoming_val="true"
        loaded_val=true
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it 'loads "false" as false' do
        incoming_val="false"
        loaded_val=false
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it 'loads "1" as true' do
        incoming_val="1"
        loaded_val=true
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it 'loads "0" as false' do
        incoming_val="0"
        loaded_val=false
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it "reports errors for any other string" do
        incoming_val="Invalid boolean string"
        object, errors = subject.decode(incoming_val,'context')
        errors.first.should =~ /Could not decode a boolean from this String/
        object.should be_nil
      end
    end

    context 'for incoming integers' do
      it 'loads 1 as true' do
        incoming_val=1
        loaded_val=true
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it 'loads 0 as false' do
        incoming_val=0
        loaded_val=false
        subject.decode(incoming_val,'context').should == [ loaded_val, [] ] 
      end
      it "reports errors for any other integer" do
        incoming_val=1234
        object, errors = subject.decode(incoming_val,'context')
        errors.first.should =~ /Could not decode a boolean from this Integer/
        object.should be_nil
      end
      
    end
    
  end
end