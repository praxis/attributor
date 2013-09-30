require_relative 'spec_helper'

class Chicken
  include Attributor::Model
  attributes do
    attribute 'age', Integer, :min => 0, :max => 120, :description => "The age of the chicken"
    attribute 'email', String, :regexp => /@/, :description => "The email address of the chichen"
  end
end      

describe Attributor::Model do

  let(:name) { 'hashname' }
  let(:media_type_object) { double("mt",{:nothing=>true}) }
  let(:opts) { {:max_size => 2 } }
  let(:sub_proc) { Proc.new do
      attribute 'age', Integer, :min => 0, :max => 120, :description => "The age"
      attribute 'page', Integer, :min => 10, :max => 20, :description => "The age"
      
      attribute 'email', String, :regexp => /@/, :description => "The address"
      attribute 'chicken', Chicken, :max_size => 2, :description => "The address" do
        sa;fdl
      end
    end
  }
  
# {
#   case klass
#   when Model
#     final_klass = AnonStruct
#   else
#     final_klass = klass
#   end
#
#   'age' => Attributor::Attribute.new( final_klass, 'age', opts ) << will simply reference Integer
#   'struct' => Attributor::Attribute.new( final_klass, 'struct', opts  )  << will create a new AnonStruct and save the block in it
#   'cow' => Attributor::Attribute.new( final_klass, 'cow_friend', opts ) << will simply reference the Cow "struct"
# }
  
  subject { 
    Chicken
  }
    
  its(:native_type) { should == Chicken }
  its(:supported_options_for_type) { should == [:max_size] }
  its(:supports_sub_definition?) { should be(true) }
  
  context 'parse_block' do
    context 'initializing subdefinition' do
      let(:sub_proc) { nil }
      after(:each){subject.sub_definition.should be_a(Hash) }
      it 'initializes the sub_definition with no block' do
        subject.parse_block 
      end
      it 'initializes the sub_definition with a block' do
        subject.parse_block { hi=true}
      end
    end

    #TODO: not sure why I cannot make this work better...
    # I'd like to pass the block in parse_block, and check that instance eval gets exactly the same
    context 'invoking instance eval' do
      let(:sub_proc) { nil }
      it 'invokes instance eval witht the passed block' do
        o = Attributor::Hash.new('foo', {})
        o.should_receive(:instance_eval).once
        o.parse_block { some='block' }
      end
    end
    
  end
  
  context 'attribute parsing on (lazy) initialization' do
    
    it 'should call attribute for each definition in the block' do
      subject.should_receive(:attribute).with('age', Integer, :min => 0, :max => 120, :description => "The age")
      subject.should_receive(:attribute).with('email', String, :regexp => /@/, :description => "The address")
      subject.sub_definition #force lazy initialization
    end
    
  end
  
    
  context 'validate options' do
    
    it 'will use the common validator for the accepted options' do
      common_options = [:max_size]
      subject.should_receive(:common_options_validator_helper).with(common_options,subject.options).and_return(common_options)
      subject.validate_options(subject.options)
    end
    it 'will raise an exception if the common validator raises it' do
      expect{
        subject.should_receive(:common_options_validator_helper).and_raise("Bad stuff!")
        subject.validate_options(subject.options)        
      }.to raise_error(Exception,/Bad stuff!/)
    end
    context 'with an unknown option name' do 
      let(:opts) { {:invalid => "option"} }
      it 'will raise an exception' do
        expect{
          subject.validate_options(subject.options)
        }.to raise_error(Exception,/ERROR, unknown option/)
      end
    end
    context 'for "id"' do
      context 'with a string' do 
        let(:opts) { {:id => 'id'} }
        it 'will succeed' do
          expect{
            subject.validate_options(subject.options)        
          }.to_not raise_error
        end
      end
      context 'with a symbol' do 
        let(:opts) { {:id => :id} }
        it 'will succeed' do
          expect{
            subject.validate_options(subject.options)        
          }.to_not raise_error
        end
      end
      context 'with a something else' do 
        let(:opts) { {:id => Hash.new } }
        it 'will fail with the appropriate error' do
          expect{
            subject.validate_options(subject.options)        
          }.to raise_error(Exception,/not supported for :id defintion on a Hash/)
        end
      end

    end
  end
  
  context 'validating values' do
    context 'max_size option: checks that the hash has a maximum number of elements' do
      let(:opts) { {:max_size => 2 } }
      
      it 'passes if the number of elements is less than max_size' do
        val={'a'=>1,'b'=>2 }
        subject.validate(val,'context').should == []
      end
      it 'returns errors if the number of elements is bigger than max_size' do
        val={'a'=>1,'b'=>2 , 'c' => 3}
        subject.validate(val,'context').first.should =~ /has more attributes than the maximum allowed/
      end

    end    
  end
  
  context 'decode' do
    it 'supports loading a value from an already constructed hash object' do
      val={'a'=>1,'b'=>2 }
      subject.decode(val,'context').should == [ val, [] ]
    end

    context 'supports JSON encoded values' do
      it 'if decoded JSON is a hash' do
        val = {'a'=>1,'b'=>2 }
        json_val=JSON.dump(val)
        subject.decode(json_val,'context').should ==  [ val, [] ]
      end
      
      it 'but not if the decoded value is not a hash' do
        val = [1,2,3]
        json_val=JSON.dump(val)        
        
        object, errors = subject.decode(json_val,'context')
        errors.should_not be_empty
        errors.first =~ /JSON-encoded value doesn't appear to be a hash/ 
      end
    end

    it 'complains when trying to decode a string that it is not JSON' do
      val = "NON JSON STRING"
      object, errors = subject.decode(val,'context')
      errors.should_not be_empty
      errors.first =~ /Could not decode the incoming string as a Hash. Is it not JSON?/ 
    end

    context 'it does not support decoding hashes from other types' do
        after(:each){
          object, errors =  subject.decode(@val,'context')
          errors.should_not be_empty
          errors.first =~ /Encoded Hashes for this type is not SUPPORTED/  
        }
        it 'does not support decoding a hash from Integers' do
          @val=0
        end
        it 'does not support decoding a hash from Arrays' do
          @val=[1,2,3]
        end
        it 'does not support decoding a hash from Booleans' do
          @val=true
        end
     end
  end
  
  
  context 'loading sub-definition' do
    
    let(:sub_proc) { Proc.new do
        attribute 'age', Integer, :min => 0, :max => 120, :required=>true , :description => "The age"
        attribute 'email', String, :regexp => /@/, :description => "The address"
        attribute 'priority', String, :default => "normal", :description => "Priority"
        attribute 'primary?', Boolean, :description => "is it?"
        attribute 'deceased?', Boolean, :default => false
      end
    }
    let(:decoded_value) { {"age"=>18,"email"=>"hello@mail.com"} }
    let(:subdef_result) { subject.decode_substructure( decoded_value , 'context' ) }

    it 'returns an array with an object and an array of errors' do
      subdef_result.should be_a( Array )
      subdef_result.size.should == 2
    end

    
    context 'when required attributes are defined but not passed in' do
      let(:decoded_value) { {"email"=>"hello@mail.com"} }
      it 'returns errors when not all are present in the value' do
        subdef_result[1].should_not be_empty
        subdef_result[1].first.should =~ /context.age is required/
      end
    end
    
    context 'when all attributes are explicitly passed in' do
      context 'with "existing" values' do
        let(:decoded_value) { {"age"=>18,"email"=>"hello@mail.com","priority"=>"high","primary?"=>true,"deceased?"=>true} }
        it "always includes one key for each of them" do
          subdef_result[1].should be_empty
          subdef_result[0].keys.should =~ ["age","email","priority","primary?","deceased?"]
        end
      end
      context 'with "false" values' do
        let(:decoded_value) { {"age"=>18,"email"=>"hello@mail.com","priority"=>"high","primary?"=>false,"deceased?"=>true} }
        it "always includes one key for each of them" do
          subdef_result[1].should be_empty
          subdef_result[0].keys.should =~ ["age","email","priority","primary?","deceased?"]
        end  
      end
      context 'with "nil" values' do
        let(:decoded_value) { {"age"=>18,"email"=>"hello@mail.com","priority"=>"high","primary?"=>nil,"deceased?"=>true} }
        it "always includes one key for each of them" do
          subdef_result[1].should be_empty
          subdef_result[0].keys.should =~ ["age","email","priority","primary?","deceased?"]
        end  
      end
    end

    context 'when some of the attributes are not passed in' do
      context 'with "non-empty" default values' do
        let(:decoded_value) { {"age"=>18,"email"=>"hello@mail.com"} }
        it 'still includes them with their defaults' do
          subdef_result[1].should be_empty
          subdef_result[0].keys.should =~ ["age","email","priority","deceased?"]
          subdef_result[0]["priority"].should == "normal"
        end
      end
      context 'with "empty" defaults (value=false)' do
        let(:decoded_value) { {"age"=>18,"email"=>"hello@mail.com"} }
        it 'still includes them with their defaults' do
          subdef_result[1].should be_empty
          subdef_result[0].keys.should =~ ["age","email","priority","deceased?"]
          subdef_result[0]["deceased?"].should == false
        end
      end
    end
    
  end


  context 'sub-definition accessors' do

    context 'with a block definition' do
      it 'can check existence of named subdefinition using has_key' do
        subject.should have_key('age')     
        subject.should have_key('email')     
      end
      it 'can retrieve a named subdefinition using brackets' do
        subject['age'].should be_a(Attributor::Integer)
        subject['email'].should be_a(Attributor::String)
      end
      it 'raises an error when accessing keys using symbols' do
        expect{
          subject[:age]
        }.to raise_error(Exception,/Symbols are not allowed for attribute names/)
      end
      it 'raises an error when testing keys using symbols' do  
        expect{
          subject.has_key?(:age)
        }.to raise_error(Exception,/Symbols are not allowed for attribute names/)
      end
    end
    context 'without a block definition' do
      let(:sub_proc) { nil }      
      it 'it always return nil for an accessor (since it has initialized it with empty hash)' do        
          subject['something'].should be_nil
      end
      it 'it always returns false for a checker (since it has initialized it with empty hash)' do        
          subject.has_key?('something').should be_false
      end
    end
    
  end
  

  context 'attribute method (basic semantics)' do 
    let(:attr_name) { 'address' }
    let(:sub_proc) { nil }
    
    context 'trying to redefine the same attribute name twice' do

      it 'raises an exception' do
        expect{
          subject.attribute(attr_name, Integer, {})
          subject.attribute(attr_name, Integer, {})
        }.to raise_error(Exception,/Attribute #{attr_name} already defined/)
      end
    end
    
    it 'will use determine_class to get the appropriate attribute type to instantiate' do
      Attributor.should_receive(:determine_class).with(Integer){ Attributor::Integer }
      subject.attribute(attr_name, Integer, {})
      subject.sub_definition[attr_name].should be_a(Attributor::Integer)
    end
      
  end

  
  context 'attribute method (without inheritance)' do
    let(:opts) { {:max_size => 1 } }
    let(:sub_proc) { Proc.new {} } # To create the sub-definition, but avoid calling attribute in the initializer
    
    
    let(:attr_name) { 'address' }
    let(:attr_type) { String }
    let(:attr_opts) { {:regexp => /foobar/, :description=>"Foobar name"} }

      
    context 'with type' do
      context 'and options' do
        it 'creates a new attribute class and sets it under the attribute name in the sub-definition' do
          mock_instantiation = "this is an instance"
          Attributor::String.should_receive(:new).with(attr_name,attr_opts).and_return(mock_instantiation)
          subject.attribute(attr_name,attr_type,attr_opts)
          subject.sub_definition.should have_key(attr_name)
          subject.sub_definition[attr_name].should == mock_instantiation
        end
      end
      context 'but no options' do
        let(:attr_opts) { nil }
        it 'creates a new attribute class, passing the attribute name, and an empty options hash' do
          Attributor::String.should_receive(:new).with(attr_name,{})
          subject.attribute(attr_name,attr_type)
        end
        it 'creates a new attribute class and sets it under the attribute name in the sub-definition' do
          mock_instantiation = "this is an instance"
          Attributor::String.should_receive(:new).with(attr_name,{}).and_return(mock_instantiation)
          subject.attribute(attr_name,attr_type)
          subject.sub_definition.should have_key(attr_name)
          subject.sub_definition[attr_name].should == mock_instantiation
        end
      end
    end
    
    context 'with a block (for a Hash attribute)' do
      let(:attr_type) { Hash }
      before(:each){
        subject.attribute(attr_name,attr_type) do
          attribute "test", String
        end
      }
      it 'should instantiate the correct type, passing the correct block and save it in the subdefinition' do
          subject.sub_definition[attr_name].should be_a(Attributor::Hash)
      end
      it 'should also create a sub-attribute within the hash with the right type and name' do
        subject.sub_definition[attr_name].sub_definition['test'].should be_a(Attributor::String)
      end
    end
    
    context 'without type' do
      context 'or options' do
        it 'raises an error since the attribute cannot be properly defined' do
          expect{
            subject.attribute(attr_name)
          }.to raise_error(Exception,/type for #{attr_name} not specified/)
        end
      end
      context 'but with options' do
        it 'raises an error since the attribute cannot be properly defined' do
          expect{
            subject.attribute(attr_name, nil, {})
          }.to raise_error(Exception,/type for #{attr_name} not specified/)
        end
      end
    end
  end
  
  #########
  context 'attribute method (with inheritance)' do
    let(:inheritable) {       
      Attributor::Hash.new(name, {:max_size=>4} ) do
        attribute 'age', Integer, :min => 0, :max => 120, :description => "The age"
        attribute 'email', String, :regexp => /@/, :description => "The address"
        attribute 'address', Array, :description => "The weird address array", :required=>true
      end
    }
    
    let(:opts) { {:max_size => 1 ,:inherit_from=> inheritable} }
    
    let(:attr_name) { 'address' }
    let(:attr_opts) { {:regexp => /street/, :description=>"Foobar name"} }

      
    context 'without type specified' do
      let(:attr_type) { nil }
      
      before(:each){
          subject.attribute(attr_name, attr_type, attr_opts)
      }

      context 'or options' do
        let(:attr_opts) { {} }
        it 'inherits the same exact type and options as the inheritable' do
          subattribute = subject.sub_definition[attr_name]
          subattribute.should be_a(inheritable[attr_name].class) 
          subattribute.options.should == inheritable[attr_name].options
        end
      end
      context 'but with some options' do    
        let(:attr_opts) { {:max_size => 10 } }
        it 'gets the type from the inheritable' do
          
          subattribute = subject.sub_definition[attr_name]
          subattribute.should be_a(inheritable[attr_name].class) 
        end
        it 'gets inherits any options that are not explicitly defined' do
          subattribute = subject.sub_definition[attr_name]
          subattribute.options.should == inheritable[attr_name].options.merge(attr_opts)
        end
      end
    end
    context 'with type specified' do
      let(:attr_type) { String }
      
      before(:each){
          subject.attribute(attr_name, attr_type, {:regexp => /street/, :description=>"Foobar name"})
      }
      it 'does not inherit any option from the inheritable' do
        subattribute = subject.sub_definition[attr_name]
        subattribute.options.should == attr_opts
      end
    end
  end
  
  context 'checking subdepenencies' do
    let(:sub_proc) { Proc.new do
        attribute 'length', Integer, :min => 0, :max => 120, :description => "The length"
        attribute 'units', String, :required_if => 'length', :description => 'measuring units'
      end
    }
    it 'will call check_dependencies on all sub elements' do
      root = { 'length' => 99, 'units' => 'feet' }
      myself = root['units']
      subject.sub_definition.each_pair do |name,subdef| 
        subdef.should_receive(:check_dependencies).with(myself[name],root).and_return([])
      end
      subject.check_dependencies_substructure(myself,root)
    end
    it 'and will accumulate any errors from subdependencies' do
      root = { 'length' => 99, 'units' => 'feet' }
      myself = root['units']
      subject.sub_definition.each_pair do |name,subdef| 
        subdef.should_receive(:check_dependencies).with(myself[name],root).and_return(["#{name}-error"])
      end
      subject.check_dependencies_substructure(myself,root).should == ['length-error','units-error']
    end

  end
  
  context 'example value' do
    
    context 'when no example value given' do

      context 'when no other options given' do
        let(:opts){ {} }
        
        it 'generates a hash with examples from the definitions' do
          val = subject.example
          val.should be_kind_of ::Hash
          val.should have_key'age'
          val.should have_key 'email'
        end
      end

      context 'when max_size option is given' do
        let(:opts){ {:max_size=>2 } }
        it 'generates an example with a limited number of keys' do
          subject.example.keys.size.should <= 2
        end
      end
    end
    
    context "with an explicit example value" do
      let(:example_value) { {'a'=>1,'b'=>2} }
      let(:opts){ {:example => example_value } }
      it 'returns that value as is' do
        subject.example.should == example_value
      end
    end

  end
  
  context 'documentation' do
    pending 'describe'
  end
end
  