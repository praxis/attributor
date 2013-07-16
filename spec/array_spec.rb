require_relative 'spec_helper'
      
describe Attributor::Array do
  let(:students) { 'students' }
  let(:media_type_object) { double("mt",{:nothing=>true}) }
  let(:opts) { {:max_size => 2 } }
  let(:sub_proc) { nil }
  subject { 
    Attributor::Array.new(students, opts, &sub_proc)
  }
  its(:native_type) { should == ::Array }


  context 'parse_block' do
    let(:mock_hash_element) { double(:sub_definition => {"a"=>1,"b"=>2}) }

    context 'passing a block' do
      let(:array_block) { Proc.new  { nothing = true } }
      
      context 'trying to call it twice' do
        it 'raises an exception since it has already created the structure' do
          expect{
            subject.parse_block(&array_block)
            subject.parse_block(&array_block)
          }.to raise_error(Exception,/Array element structure already defined/)
        end
      end
      
      context 'and an element type that it is not a Hash' do
        it 'raises an error' do
          expect{
            subject.options[:element_type] = ::Integer
            subject.parse_block(&array_block)
          }.to raise_error(/Arrays can only be defined by a block when element_type is a Hash/)
        end
      end
      
      context 'and an element_type that is a Hash' do
        it 'it does not raise an error' do
          subject.options[:element_type] = Attributor::Hash
          subject.parse_block(&array_block)
          subject.sub_definition.should be_a( Attributor::Hash )
        end
      end
      
      context 'and no element type' do
        it 'it defaults to creating a hash attribute' do
          subject.parse_block(&array_block)
          subject.sub_definition.should be_a( Attributor::Hash )  
        end
      end
      
      context 'without inheriting' do
        let(:sub_options) { {} }
        before(:each) {
          Attributor::Hash.should_receive(:new).with(an_instance_of(String),sub_options).and_return(mock_hash_element)
          subject.parse_block(&array_block)
        }
        
        it 'will set its special array element definition key to the created attribute' do
          subject.sub_definition.should == mock_hash_element
        end  
      end

      context 'when the array attribute was inheriting from a wrong object' do
        context 'that it does not derive from Attribute' do
          let(:opts) { {:inherit_from => {:hello=>'there'} } }
          it 'raises an error' do
            expect {
              subject.parse_block(&array_block)
            }.to raise_error(/attribute #{students} cannot inherit from objects that do are not 'Attribute' type/)
          end
        end
        context 'that the inheritor is not an Array atrribute' do
          let(:opts) { {:inherit_from => Attributor::Hash.new(students,{}) } }
          it 'raises an error' do
            expect {
              subject.parse_block(&array_block)
            }.to raise_error(/this Attribute is not an Array/)
          end
        end
      end
      
      context 'when the array attribute was inheriting from another Array attribute' do
        let(:opts) { {:inherit_from => Attributor::Array.new(students,{}) } }
        let(:sub_options) { {:inherit_from => subject.instance_variable_get(:@inherit_from).sub_definition} }
      
        it 'creates the hash attribute passing inherit_from set to the sub_definition object of the array' do       
          Attributor::Hash.should_receive(:new).with(an_instance_of(String),sub_options).and_return(mock_hash_element)
          subject.parse_block(&array_block)
        end
      end
    end

    context 'NOT passing a block' do
      let(:array_block) { nil }
      
      context 'trying to call it twice with an element_type' do
        let(:opts) { {:element_type => Integer} }
        it 'raises an exception since it has already created the structure' do
          expect{
            subject.parse_block(&array_block)
            subject.parse_block(&array_block)
          }.to raise_error(Exception,/Array element structure already defined/)
        end
      end
      
      context 'and an element_type that is a Hash' do
        it 'it does not raise an error' do
          subject.options[:element_type] = Attributor::Hash
          subject.parse_block(&array_block)
          subject.sub_definition.should be_a( Attributor::Hash )
        end
      end
      context 'and an element_type that is another valid type (i.e, an Integer)' do
        it 'it does not raise an error' do
          subject.options[:element_type] = Attributor::Integer
          subject.parse_block(&array_block)
          subject.sub_definition.should be_a( Attributor::Integer )
        end
      end
      context 'and an element_type that not an Attribute-derived' do
        it 'it does raise an error' do
          subject.options[:element_type] = ::Integer
          expect{
            subject.parse_block(&array_block)
          }.to raise_error(Exception,/Error: element_type option for Array/)
        end
      end
      context 'and no element_type at all' do
        let(:opts) { {} }
        it 'it assumes that elements can take any structure' do
          subject.parse_block(&array_block)
          subject.sub_definition.should be_nil
        end
      end
      
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
    context 'for element_type' do
      context 'with a non attributor type (which does not have an equivalent)' do 
        let(:opts) { {:element_type => Object} }
        it 'will raise an exception' do
          expect{
            subject.validate_options(subject.options)
          }.to raise_error(Exception,/not supported for element_type/)
        end
      end
      context 'with direct Attributor class' do 
        let(:opts) { {:element_type => Attributor::Integer} }
        it 'will not raise an exception' do
          expect{
            subject.validate_options(subject.options)        
          }.to_not raise_error
        end
      end
      context 'with a non Attributor class (but for which there is an equivalent one)' do 
        let(:opts) { {:element_type => ::Integer} }
        it 'will not raise an exception' do
          expect{
            subject.validate_options(subject.options)        
          }.to_not raise_error
        end
      end
      context 'when passing an element type that has an equivalent attributor' do
        it 'will convert the stored element_type option' do
          subject.instance_variable_set(:@options, {:element_type =>  ::Integer } )
          subject.validate_options(subject.options)        
          subject.options[:element_type].should == Attributor::Integer
        end
        
      end
    end
  end
  
  context 'generate_subcontext' do
    let(:subindex) { 4 }
    subject { Attributor::Array.generate_subcontext( context, subindex ) }
    context 'context is not nil' do
      let(:context) { "mycontext"}
      it 'makes a square bracket-type index string' do
        subject.should == "mycontext[4]"
      end
    end
    context 'if context is nil' do
      let(:context) { nil }
      it 'treats it as empty string and simply adds the bracketed portion' do
        subject.should == "[4]"
      end
    end
  end
  
  context 'decode_array_proper' do
    subject{ Attributor::Array.decode_array_proper( the_value )}
    context 'if it is an array object' do
      let(:the_value) { ['a','b','c']}
      it 'successfully decodes(returns) the same exact value' do
        subject.should be_a( Array )
        subject[1].should be_empty
        subject[0].should == the_value
      end
    end
    context 'if it is a string object' do
      after(:each) do
         subject.should be_a( Array ) 
         subject.size.should == 2
       end
      context 'non JSON encoded' do
        let(:the_value) { "this is not, a JSON, string"}      
        it 'returns errors if string cannot be JSON decoded' do
          subject[1].first.should =~ /Could not decode the incoming string as an Array/
          subject[0].should be_nil
        end
      end
      context 'encoded in JSON' do
        context 'but not as an array' do
          let(:the_value) { JSON.dump({'this'=>'is','a'=>'hash'})}    
          it 'returns an error about the type mismatch' do
            subject[1].first.should =~ /JSON-encoded value doesn't appear to be an array/
            subject[0].should be_nil
          end
          
        end
        context 'as an array' do
          let(:the_value) { JSON.dump(['a','b','c'])}    
          it 'successfully returns the value if JSON decoding yields an array object' do
            subject[1].should be_empty
            subject[0].should == ['a','b','c']
          end
        end
      end
    end
    
    context 'if it is non-supported type of object' do
      let(:the_value) { 123 }
      it 'returns errors complaining about the unknown type' do
        subject[1].first.should =~ /Do not know how to decode an array from a #{the_value.class.name}/
        subject[0].should be_nil
      end
    end

  end
  
  context 'decode (without element_coercing)' do 
      let(:opts) { {} }
      it 'supports loading a value from an already constructed hash object' do
        val=['a','b']
        subject.decode(val,'context').should == [val, [] ]
      end
      
      context 'supports loading a value JSON encoded arrays' do
        it 'if decoded JSON is an array' do
          val = ['a','b']
          json_val=JSON.dump(val)
          subject.decode(json_val,'context').should == [val, [] ]
        end
      
        it 'but not if the decoded value is not an array' do
          val = {'a'=>1,'b'=>2 }
          json_val=JSON.dump(val)        
        
          object, errors = subject.decode(json_val,'context')
          errors.should_not be_empty
          errors.first =~ /JSON-encoded value doesn't appear to be an array/ 
        end
      end
  end
  
  context 'loading (coercing) individual elements of the array' do
    let(:element1) { {'a'=>1} }
    let(:element2) { {'b'=>2} }
    context 'when element_type is not defined (and not defined by a block)' do
      let(:opts) { {} }
      let(:sub_proc) { nil }
      it 'does not do any additional processing of elements' do
        val=['a','b']
        subject.decode(val,'context').should == [ val, [] ]
      end
    end
    context 'when element_type is not defined (but defined by a block)' do
      let(:opts) { {} }
      let(:sub_proc) { 
        Proc.new do
          hello = 'there'    
        end
      }
      it 'processes the elements as individual hashes' do
        val=[ element1 , element2 ]
        Attributor::Hash.any_instance.should_receive(:decode)
                                      .with( element1,'context[0]').once
                                      .and_return( [ element1, [] ] )
        Attributor::Hash.any_instance.should_receive(:decode)
                                     .with( element2,'context[1]').once
                                     .and_return(  [ element2, [] ] )
        subject.decode(val,'context').should == [ val, [] ]
      end
    end
    context 'when element_type is a hash (and defined by a block)' do
      let(:opts) { {:element_type => Hash} }
      let(:sub_proc) { 
        Proc.new do
          hello = 'there'    
        end
      }
      it 'processes the elements as individual hashes' do
        val=[ element1 , element2 ]
        Attributor::Hash.any_instance.should_receive(:decode)
                                      .with( element1,'context[0]').once
                                      .and_return(  [ element1, [] ] )
        Attributor::Hash.any_instance.should_receive(:decode)
                                     .with( element2,'context[1]').once
                                     .and_return(  [ element2, [] ] )
        subject.decode(val,'context').should == [ val, [] ]
      end
    end
    context 'when element_type is another supported AttributeType' do
      let(:opts) { {:element_type => Integer} }
      let(:element1) { 1000 }
      let(:element2) { 2000 }
      
      it 'it invokes the type-specific loader for each' do 
        val=[ element1 , element2 ]
        Attributor::Integer.any_instance.should_receive(:decode)
                                      .with( element1,'context[0]').once
                                      .and_return(  [ element1, [] ] )
        Attributor::Integer.any_instance.should_receive(:decode)
                                     .with( element2,'context[1]').once
                                     .and_return(  [ element2, [] ])
        subject.decode(val,'context').should == [ val, [] ]
      end
    end
    context 'when element_type is supported but requires coercion' do
      let(:opts) { {:element_type => Integer} }
      let(:element1) { "1000" }
      let(:element2) { "2000" }
      
      it 'it makes sure to return the result of the individual decodes' do 
        val=[ element1 , element2 ]
        Attributor::Integer.any_instance.should_receive(:decode)
                                      .with( element1,'context[0]').once
                                      .and_return( [ element1.to_i, [] ] )
        Attributor::Integer.any_instance.should_receive(:decode)
                                     .with( element2,'context[1]').once
                                     .and_return( [ element2.to_i, [] ] )
        subject.decode(val,'context').should == [ [element1.to_i, element2.to_i], [] ]
      end
    end
      
  end

  context 'decode_substructure' do

    let(:opts) { {:element_type => Integer} }
    let(:decoded_value) { [1,2] }
    let(:subdef_result) { subject.decode_substructure( decoded_value , 'context' ) }

    it 'returns a hash with errors and object keys' do
      subdef_result.should be_a(Array)
      subdef_result.size.should == 2
    end
    
    it 'calls load with the right value and context for each element of the array and returns the values in the array' do
      #returns the result of a "load" for each element of the array' do
      subject.sub_definition.should_receive(:load).with(1,'context[0]').and_return([ 1,[] ])
      subject.sub_definition.should_receive(:load).with(2,'context[1]').and_return([ 2,[] ])
      subdef_result
    end
    
    context 'collecting values' do
      context 'when all elements have "existing" values' do 
        it 'returns an object with a value for each incoming element' do
          subject.sub_definition.should_receive(:load).with(1,'context[0]').and_return([ 1,[] ])
          subject.sub_definition.should_receive(:load).with(2,'context[1]').and_return([ 2,[] ])
          subdef_result[0].should == [1,2]
        end
      end
      context 'when some elements have "false" values' do 
        let(:opts) { {:element_type => Boolean} }
        let(:decoded_value) { [1,false] }
        it 'still returns them in the result' do
          subject.sub_definition.should_receive(:load).with(1,'context[0]').and_return( [ 1, [] ] )
          subject.sub_definition.should_receive(:load).with(false,'context[1]').and_return([ false, [] ])
          subdef_result[0].should == [1,false]
        end
      end
      context 'when some elements have "nil" values' do 
        let(:decoded_value) { [1,nil] }
        it 'still returns them in the result' do
          subject.sub_definition.should_receive(:load).with(1,'context[0]').and_return([ 1,[] ])
          subject.sub_definition.should_receive(:load).with(nil,'context[1]').and_return( [ nil, [] ])
          subdef_result[0].should == [1,nil]
        end
      end

    end

    context 'collecting errors' do    
      let(:decoded_value) { [1,2,3] }
      it 'aggregates all the errors from the individual element loads' do
        subject.sub_definition.should_receive(:load).with(1,'context[0]').and_return([ 1, ['error1'] ])
        subject.sub_definition.should_receive(:load).with(2,'context[1]').and_return([ 2, ['error2.1','error2.2'] ])
        subject.sub_definition.should_receive(:load).with(3,'context[2]').and_return([ 2, [] ])  
        subdef_result[1].should == ['error1','error2.1','error2.2']
      end
    end
    
  end
  
  
  context 'checking subdepenencies' do
    context 'when defining structure through hashes' do 
      let(:sub_proc) { Proc.new do
          attribute 'length', Integer, :min => 0, :max => 120, :description => "The length"
          attribute 'units', String, :required_if => 'length', :description => 'measuring units'
        end
      }
      it 'will call check_dependencies on all sub elements' do
        root = [{ 'length' => 99, 'units' => 'feet' }, { 'length' => 1000, 'units' => 'cm' }]
        myself = root
        subject.sub_definition.should_receive(:check_dependencies).with(myself[0],root).and_return([])
        subject.sub_definition.should_receive(:check_dependencies).with(myself[1],root).and_return([])
        subject.check_dependencies_substructure(myself,root)
      end
      it 'and will accumulate any errors from subdependencies' do
        root = [{ 'length' => 99, 'units' => 'feet' }, { 'length' => 1000, 'units' => 'cm' }]
        myself = root
        subject.sub_definition.should_receive(:check_dependencies).with(myself[0],root).and_return(['error1 from item 0'])
        subject.sub_definition.should_receive(:check_dependencies).with(myself[1],root).and_return(['error1 from item 1','error2 from item 1'])
        subject.check_dependencies_substructure(myself,root).should == ['error1 from item 0','error1 from item 1','error2 from item 1']
      end
    end
  end
end