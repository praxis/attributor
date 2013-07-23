require_relative 'spec_helper'
      
describe Attributor::String do

  let(:the_name){ 'string_name' }
  let(:opts) { {:regexp => /FooBar/ } }
  subject { 
    Attributor::String.new(the_name, opts)
  }
  its(:native_type) { should == ::String }  
  
  its(:supported_options_for_type) { should == [:regexp] }

  
  it 'raises an error if you try to instantiate it with a block' do
    expect{
      Attributor::String.new(the_name, opts) do
        hello = 'there'
      end
    }.to raise_error(Exception,/does not implement attribute sub-definition parsing/)    
  end
  
  context 'validate options' do
    it 'will use the common validator for the accepted options' do
      common_options =  [:regexp]
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
      let(:opts) { {:regexp => /FooBar/, :invalid => "option"} }
      it 'will raise an exception' do
        expect{
          subject.validate_options(subject.options)        
        }.to raise_error(Exception,/ERROR, unknown option/)
      end
    end
  end
  
  context 'validate' do
    context 'for option :regexp' do
      let(:opts) { {:regexp=>/Regexp/ } }
      it 'returns no errors if the value matches the regexp' do
        val="this is a Regexp for real"
        subject.validate(val,'context').should == []
      end
      it 'returns errors if the value does not match the regexp' do
        val="this is not a Re-Ge-XP"
        subject.validate(val,'context').first.should =~ /value does not match regexp/
      end
    end
  end

  context 'decode' do
    context 'for incoming string values' do
      it 'suceeds by simply using the incoming object' do
        val="this is a string"
        subject.decode(val,'context').should == [ val, [] ]
      end
    end
    
    context 'for incoming values of non-supported types (anything not a string)' do
      it 'always returns errors complaining about the unknown type' do
        val={'this'=>'is', 'a'=>'hash' }
        object, errors = subject.decode(val,'context')
        errors.first.should =~ /Do not know how to load a string from/
        object.should be_nil
      end
    end
  end

  context 'example value' do
    context 'when an :example option is available' do
      context 'defined as a string' do
        let(:opts) { {:example=>"Example string" } }
        it 'returns it as is' do
          subject.example.should == "Example string"
        end
      end
      context 'defined as a Regex' do
        let(:opts) { {:example=>/\w{10}/ } }
        it 'generate a string from it' do
          subject.example.should =~ /\w{10}/
        end
      end
    end
    context 'when no :example is passed' do
      context 'but the attribute has a regexp defined' do
        let(:opts) { {:regexp=>/Boom/} }
        it 'will return a string matching the regexp of the attribute' do
          subject.example.should =~ /Boom/
        end
      end
      context 'and no other option exists' do
        let(:opts) { {} }
        it 'will return nil (nothing particular to be done)' do
          subject.example.should == nil
        end
      end
    end
  end
  
end

