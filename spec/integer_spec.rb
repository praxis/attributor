require_relative 'spec_helper'
      
describe Attributor::Integer do

  let(:the_name){ 'integer_name' }
  let(:opts) { {:min => 2 } }
  subject { 
    Attributor::Integer.new(the_name, opts)
  }
  its(:native_type) { should == ::Integer }  
  its(:supported_options_for_type) { should == [:min,:max] }
  
  
  it 'raises an error if you try to instantiate it with a block' do
    expect{
      Attributor::Integer.new(the_name, opts) do
        hello = 'there'
      end
    }.to raise_error(Exception,/does not implement attribute sub-definition parsing/)    
  end
  
  context 'validate options' do
    it 'will use the common validator for the accepted options' do
      common_options = [:min,:max]
      subject.should_receive(:common_options_validator_helper).with(common_options,subject.options).and_return(common_options)
      subject.validate_options(subject.options)
    end
    it 'will raise an exception if the common validator raises it' do
      expect{
        subject.should_receive(:common_options_validator_helper).and_raise("Bad stuff!")
        subject.validate_options(subject.options)        
      }.to raise_error(Exception,/Bad stuff!/)
    end
    
    context 'with a single unknown option name' do 
      let(:opts) { {:invalid => "option"} }
      it 'will raise an exception' do
        expect{
          subject.validate_options(subject.options)        
        }.to raise_error(Exception,/ERROR, unknown option/)
      end
    end
    context 'with one of the options being unknown' do 
      let(:opts) { {:min => 2, :invalid => "option"} }
      it 'will raise an exception' do
        expect{
          subject.validate_options(subject.options)        
        }.to raise_error(Exception,/ERROR, unknown option/)
      end
    end
  end
  
  context 'validate' do
    context 'for option :max' do
      let(:opts) { {:max => 99 } }
      it 'returns no errors if the value is less than max' do
        val=50
        subject.validate(val,'context').should == []
      end
      it 'returns no errors if the value is exactly max' do
        val=opts[:max]
        subject.validate(val,'context').should == []
      end
      it 'returns errors if the value is bigger than the max' do
        val=100
        subject.validate(val,'context').first.should =~ /value is larger than the allowed max/
      end
    end

    context 'for option :min' do
      let(:opts) { {:min => 10 } }
      it 'returns no errors if the value is higher than min' do
        val=20
        subject.validate(val,'context').should == []
      end
      it 'returns no errors if the value is exactly min' do
        val=opts[:min]
        subject.validate(val,'context').should == []
      end
      it 'returns errors if the value is smaller than the min' do
        val=1
        subject.validate(val,'context').first.should =~ /value is smaller than the allowed min/
      end
    end

  end

  context 'decode' do
    context 'for incoming integer values' do
      it 'suceeds by simply using the incoming object' do
        val=1
        subject.decode(val,'context').should == {:errors=>[], :loaded_value => val}
      end
    end
    context 'for incoming string values' do
      it 'decodes it if the string represents an integer' do
        val="1024"
        subject.decode(val,'context').should == {:errors=>[], :loaded_value => val.to_i}
      end
      context 'returns errors if the string' do
        it 'contains simple alphanumeric text' do
          val="not an integer"
          tuple = subject.decode(val,'context')
          tuple[:errors].first.should =~ /Could not decode an integer from this String./
          tuple[:loaded_value].should be_nil
        end
        it 'contains a floating point value' do
          val="98.76"
          tuple = subject.decode(val,'context')
          tuple[:errors].first.should =~ /Could not decode an integer from this String./
          tuple[:loaded_value].should be_nil
        end
      end
    end
    
    context 'for incoming values of non-supported types' do
      it 'always returns errors complaining about the unknown type' do
        val={'this'=>'is', 'a'=>'hash' }
        tuple = subject.decode(val,'context')
        tuple[:errors].first.should =~ /Do not know how to load an integer from/
        tuple[:loaded_value].should be_nil
      end
    end
  end

end

