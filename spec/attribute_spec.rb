require_relative 'spec_helper'
      
describe Attributor::Attribute do
    
  module Attributor
    class MyType < Attribute
      def self.native_type
        ::String
      end
    end
  end
  
  let(:name) { 'foobar' }
  let(:media_type_object) { double("mt",{:nothing=>true}) }
  let(:opts) { {} }
  let(:attribute) { Attributor::MyType.new(name, opts)  }
  
  subject { attribute }
  context 'for simple type attribute superclasses' do
    context 'initializing' do
      
      its(:name) {should == name }
      its(:options) {should == opts }
      its(:sub_definition) {should be_nil }
   
      context 'when inheriting' do
        let(:opts) { {:description=>"FOO", :inherit_from => media_type_object} }
        it 'extracts inherit_from option into a different instance variable' do     
          subject.inherit_from.should == media_type_object 
          opts.delete(:inherit_from)
          subject.options.should == opts 
        end
        
      end


      context 'validating options' do
        context 'using valid options' do
          let(:opts) { {:description=>"FOO", :required => true} }
          it 'calls validate_universal_options without raising' do
            Attributor::MyType.any_instance.should_receive(:validate_universal_options).and_return([:description,:required])      
            expect {
              Attributor::MyType.new(name, opts)
            }.to_not raise_error
          end

          context 'with a common one' do
            let(:opts) { {:description=>"FOO", :required => true, :min=>"option"} }
            it 'calls validate_options of the instance with remaining options' do
              Attributor::MyType.any_instance.should_receive(:validate_universal_options).and_return([:description,:required])      
              Attributor::MyType.any_instance.should_receive(:validate_options).with({:min=>"option"})
              obj = Attributor::MyType.new(name, opts)
              obj.options.should == opts
            end
          end
        end
        
        context 'using invalid options since the base class does not implement any specific handling' do
          let(:opts) { {:description=>"FOO", :required => true, :class_specific=>"option"} }
          it 'calls validate_universal_options' do
            Attributor::MyType.should_receive(:native_type).and_return(::String)
            Attributor::MyType.any_instance.should_receive(:validate_universal_options).and_return([:description,:required])  
            expect {
              Attributor::MyType.new(name, opts)
            }.to raise_error(Exception,/ERROR, unknown option/)    
          end
        end
      end
      
        
      context 'with a block definition' do
        context 'for simple type attribute superclasses' do
          it 'raises an exception' do
              expect { 
                Attributor::MyType.new('somename', {}) do
                  attribute :sub1, Integer 
                end 
              }.to raise_error(Exception, /does not implement attribute sub-definition parsing/ )        
            end
        end
        context 'for complex type attribute superclasses' do
          it 'calls parse_block ' do
            random_info = {:fake_stuff=>true}
            Attributor::MyType.any_instance.should_receive(:parse_block)
            attr_object = Attributor::MyType.new(name, opts) do 
                    @mystuff = random_info #we don't eval this in MyType...
                  end 
          end
  
        end  
      end
    end
    
 
    context 'managing attribute classes' do
      
      module Attributor
        class NonDerivingAttribute; end
      end
      context 'finding attribute class' do
        it 'returns a class if the named constant exists, and derives from Attributor::Attribute' do
          Attributor.find_class("MyType").should == Attributor::MyType
        end
        it 'raises and exception if the named constant exists, but it does not derive from Attributor::Attribute' do
          expect { 
            Attributor.find_class("NonDerivingAttribute")
          }.to raise_error(Exception, /Could not find attribute type for/ )      
        end

        it 'raises an exception if the named constant cannot be found' do
          expect { 
            Attributor.find_class("NonExistingClass")
          }.to raise_error(Exception, /Could not find class with name/ )      
        end
        
      end
    
      context 'determine class' do
        module Foo
          module Bar
            class MyType
            end
          end
        end
        it 'returns the passed type if it derives from Attributor::Attribute' do        
          Attributor.determine_class(Attributor::MyType).should == Attributor::MyType      
        end
        it 'returns the classif it does not derives from Attributor::Attribute' do
          Attributor.should_receive(:find_class).with("MyType").and_return(Attributor::MyType)
          Attributor.determine_class(Foo::Bar::MyType).should == Attributor::MyType      
        end
      end
    end
    
    context 'native type' do
      it 'calls and returns the class native type' do
        subject.native_type.should == ::String
      end
    end  
    

    context 'decode' do
      let(:attribute) { Attributor::Attribute.new('foo',{}) }
      let(:tuple) { subject.decode("val","context") }
      
      it 'returns a hash tuple with errors and loaded value' do
        tuple.should be_a(Array)
        tuple.size.should == 2        
      end
      
      it 'implements a basic noop method that returns the value "as is" by default with no errors' do
        tuple[0].should == "val"
        tuple[1].should == []
      end
    end
  
    context 'base validate_options' do
      let(:opts) { {:min => 3,:max=>4} }
      it 'calls validate_options of the instance with remaining options' do
        supported = [:min,:max,:regexp]
        # Need to expect it twice (one for the subject initialization and one for our explicit validate_options call)
        Attributor::MyType.any_instance.should_receive(:supported_options_for_type).twice.and_return(supported)
        Attributor::MyType.any_instance.should_receive(:common_options_validator_helper).with(supported,opts).twice.and_return(opts.keys)
        expect{       
          subject.validate_options(opts) 
        }.to_not raise_exception(Exception)
      end
    end
    
    context 'validate_type' do  
      it 'returns no errors when comparing the object with the native type of the class' do
        subject.validate_type("val","context").should == []
      end
      
      it 'returns errors when the compared object does not match with the native type of the class' do
        Attributor::MyType.stub(:native_type).and_return(::Integer)        
        errors = subject.validate_type("val","context")
        errors.should_not be_empty 
        errors.first.should  =~ /has the wrong type/
      end
    end
  
    
    context 'enforces :required option when loading' do
      let(:context) { "context" }
      
      context 'loading a value that it is required' do
        let(:opts) { {:required => true} }
        it 'returns the error when nil (and a nil loaded value result)' do
          object, errors = subject.load( nil, context )
          errors.first.should =~ /is required/
          object.should be_nil
        end
        it 'does not call any of the loading or validation functions' do
          subject.should_not_receive(:decode)
          subject.should_not_receive(:validate_type)
          subject.should_not_receive(:validate)
          result = subject.load( nil, context )
        end
      end    
    end
    context 'enforces allowed :values option when loading' do
      let(:context) { "context" }
      let(:opts) { {:values => ['one','two']} }      
      context 'when loading a value that it is allowed' do
        it 'returns no errors' do
          object, errors = subject.load( 'two', context )
          errors.should == []
        end
      end    
      context 'when loading a value that it is NOT allowed' do
        it 'returns an error indicating the violation' do
          object, errors = subject.load( 'three', context )
          errors.first.should =~ /value three is not within the allowed values/
        end
      end    

    end
    context 'supports :default values when loading nil values' do
      let(:type_errors) { ["some type error"] }
      let(:value_errors) { ["some value error"] }
      let(:loaded_value){ 'some value' }
      let(:loaded) { [ loaded_value, [] ] }
      let(:context) { "context" }

      context 'with a :default option defined' do
        let(:default_value){ 'the default' }
        let(:loaded_value){ default_value }
        let(:opts) { {:default => default_value} }
        it 'it loads the default object instead' do
          subject.should_receive(:decode).with( default_value, context ).and_return(loaded)
          subject.should_receive(:validate_type).with( loaded_value, context ).and_return(type_errors)
          subject.should_receive(:validate).with( loaded_value, context ).and_return(value_errors)
          
          result = [ loaded_value, type_errors+value_errors ]
          subject.load( nil, context ).should == result
        end
      end
      context 'without a :default option defined' do
        let(:opts) { {} }
        it 'it skips decoding and everything else' do
          subject.should_not_receive(:decode)          
          subject.load( nil, context ).should == [ nil, [] ] 
        end
      end
    end

    context 'parsing values' do
      
      let(:value_errors) { ["some value error"] }
      let(:loaded_value) { "foobar" }
      let(:loaded_errors) { ['something went wrong'] }
      let(:loaded) { [loaded_value, loaded_errors ] }
      let(:incoming_value) { 'foobar' }
      context 'always' do
        it 'should call load (with no context) and check dependencies' do
          subject.should_receive(:load).with( incoming_value, nil ).and_return(loaded)
          subject.should_receive(:check_dependencies).and_return([])
          subject.parse( incoming_value )
        end
        it 'should return all the errors from load' do
          subject.should_receive(:load).with( incoming_value, nil ).and_return(loaded)
          subject.parse( incoming_value )[1].should == loaded_errors
        end
        it 'should add any errors from check dependencies to the errors array' do
          subject.should_receive(:load).with( incoming_value, nil ).and_return(loaded)
          dependency_errors = ['dependency error']
          subject.should_receive(:check_dependencies).with( loaded_value, loaded_value ).and_return(dependency_errors)
          dupped_errors = loaded_errors.dup          
          subject.parse( incoming_value )[1].should == ( dupped_errors + dependency_errors)
        end
        it 'should return a nil object if there are any errors' do
          subject.should_receive(:load).with( incoming_value, nil ).and_return(loaded)
          object, errors = subject.parse( incoming_value )
          errors.should == loaded_errors
          object.should be_nil
        end
      end
      context 'without any dependency requirements (or errors)' do
        let(:loaded_errors) { [] }
        it 'should return the same as load' do
          subject.should_receive(:load).with( incoming_value, nil ).and_return(loaded)
          subject.should_receive(:check_dependencies).with( loaded_value, loaded_value ).and_return([])
          subject.parse( incoming_value ).should == loaded
        end
      end 
    end

    context 'loading values' do
      let(:type_errors) { ["some type error"] }
      let(:value_errors) { ["some value error"] }
      let(:loaded_value) { "foobar" }
      let(:loaded) { [ loaded_value, [] ] }
      let(:context) { "context" }

      context 'with a type not defining validate' do
        it 'should not call validate value and therefore not carry errors for it' do
          subject.should_receive(:decode).with( 'something', context ).and_return(loaded)
          subject.should_receive(:validate_type).with( loaded_value, context ).and_return(type_errors)
          subject.should_receive(:respond_to?).with(:validate).once.and_return(false) #One for the constructor, one here
          subject.should_not_receive(:validate)
          
          subject.load( 'something', context ).should == [ loaded_value, type_errors ]
          
        end
      end
      
      context 'with a type defining validate' do
        before(:each) do
          subject.should_receive(:decode).with( 'something', context ).and_return(loaded)
          subject.should_receive(:validate_type).with( loaded_value, context ).and_return(type_errors)
          subject.should_receive(:validate).with( loaded_value, context ).and_return(value_errors)
        end      
        
        context 'without subdefinition' do
          it 'calls decode,validate_type and validate and return the correct errors and object hash' do
            subject.should_not_receive(:decode_substructure)
            subject.load( 'something', context ).should == [ loaded_value, type_errors+value_errors ]
          end
        end
        
        context 'that have a sub definition that is not empty' do
          before(:all) {
            Attributor::MyType.any_instance.stub(:parse_block).and_return(nil)
          }
          let(:attribute) { 
            a=Attributor::MyType.new(name, opts) do 
                 hello= true
               end
            a.instance_variable_set(:@sub_definition, {'something'=>'not-empty'} )
            a
            }
          it 'also calls decode_substructure and accumulates any errors to the result' do
            sub_result= [ "my sub-object", ["some subdef error"] ] 
            subject.should_receive(:decode_substructure).with(loaded_value,context).and_return(sub_result)
            subject.load('something',context).should == [  "my sub-object", type_errors+value_errors+["some subdef error"] ]
          end
        end
      end
    end 
    
    
    context 'validate_universal_options' do
      context 'passes validations for universal keys with their correct types' do  

        context 'for :values option' do
          let(:opts) {{  :values=>["blue","green"] }}
          it 'suceeds when it is an Array' do
            expect{ subject.validate_universal_options }.to_not raise_error
          end
        end

        context 'for :required option' do
          let(:opts) {{  :required => true }}
          it 'suceeds when it is a boolean' do
            expect{ subject.validate_universal_options }.to_not raise_error
          end
        end
        
        context 'for :required_if option' do
          it 'suceeds when it is a string' do
            subject.instance_variable_set(:@opts,{  :required_if => 'attribute.name' })
            expect{ subject.validate_universal_options }.to_not raise_error
          end
          it 'suceeds when it is a Hash' do
            subject.instance_variable_set(:@opts,{  :required_if => { 'some_config.cvs_type' => 'git' } })
            expect{ subject.validate_universal_options }.to_not raise_error
          end
          it 'suceeds when it is a Proc' do
            subject.instance_variable_set(:@opts,{  :requred_if => Proc.new {|root| root['some_config']['cvs_type'] =~ 'git' } })
            expect{ subject.validate_universal_options }.to_not raise_error
          end
          it 'suceeds when it is a lambda' do
            subject.instance_variable_set(:@opts,{  :requred_if => lambda {|root| root['some_config']['cvs_type'] =~ 'git' } })
            expect{ subject.validate_universal_options }.to_not raise_error
          end

        end

        context 'for :description option' do
          let(:opts) {{  :description => "Lorem ipsum"}}
          it 'suceeds when it is a string' do
            expect{ subject.validate_universal_options }.to_not raise_error
          end
        end

        context 'for :default option' do
          let(:opts) {{  :default => "DefaultValue" }}
          it 'suceeds when it is the same type of the attribute' do
            expect{ subject.validate_universal_options }.to_not raise_error
          end
        end
      end

      context 'when :require is combined with :default' do
        context 'and :required is true' do
          let(:opts) {{  :required => true , :default => "foobar"}}
          it 'fails since we need to force a value instead of defaulting' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/cannot be enabled in combination with :default/)
          end
        end
        context 'and :required is false' do
          let(:opts) {{  :required => false , :default => "foobar"}}
          it 'succeeds since we can perfectly set a default value' do
            expect{ subject.validate_universal_options }.to_not raise_error
          end
        end
      end

      context 'when :required_if is combined with :require' do
        context 'and :required is true' do
          let(:opts) {{  :required => true , :required_if => 'foobar' }}
          it 'fails since they cannot be used at the same time' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/Required_if cannot be specified together with :required/)
          end
        end
        context 'and :required is false' do
          let(:opts) {{  :required => true , :required_if => 'foobar' }}
          it 'still fails since it would be weird to allow you to explicitly do so' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/Required_if cannot be specified together with :required/)
          end
        end
      end

      
      context 'fails validations for universal keys with incorrect types' do  

        context 'for :values option' do
          let(:opts) {{  :values=>"Not an array" }}
          it 'fails when it is not an Array' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/Allowed set of values requires an array/)
          end
        end

        context 'for :required option ' do
          let(:opts) {{  :required => "not a boolean" }}
          it 'fails when it is not boolean' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/Required must be a boolean/)
          end        
        end

        context 'for :description option' do
          let(:opts) {{  :description => 1024 }}
          it 'fails when it is not a string' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/Description value must be a string/)
          end
        end

        context 'for :default option' do
          let(:opts) {{  :default => [1,2,3] }}
          it 'fails when it is not the same type of the attribute' do
            expect{ subject.validate_universal_options }.to raise_error(Exception,/Default value doesn't have the correct type/)
          end
        end
      end
      
    end
      
    context 'common_options_validator_helper' do
      

      context 'passes correct validations' do  
        let(:options_hash) {{
          :min=> 1, :max => 10, :max_size=>50, 
          :regexp => /^Foo/
        }}
        context 'returning the validated (processed) optinos' do
          it 'returns them all when they are correct' do
            result = subject.common_options_validator_helper( [:min,:regexp], options_hash )
            result.should =~ [:min,:regexp]
          end
          it 'returns none, when none are passed' do
            subject.common_options_validator_helper( [], options_hash ).should == []
          end
        end
        it 'suceeds when :min option is an Integer' do
          expect{ subject.common_options_validator_helper( [:min], options_hash ) }.to_not raise_error
        end
        it 'suceeds when :max option is an Integer' do
          expect{ subject.common_options_validator_helper( [:max], options_hash ) }.to_not raise_error
        end
        it 'suceeds when :max_size option is an Integer' do
          expect{ subject.common_options_validator_helper( [:max_size], options_hash ) }.to_not raise_error
        end
        it 'suceeds when :regexp option is a Regexp' do
          expect{ subject.common_options_validator_helper( [:regexp], options_hash ) }.to_not raise_error
        end
      end
      context 'errors on incorrect options' do  
        let(:options_hash) {{
          :min=> "a", :max => "b", :max_size=>"c", 
          :regexp => "/^Foo/"
        }}
        it 'suceeds when :min option is an Integer' do
          expect{ subject.common_options_validator_helper( [:min], options_hash ) }.to raise_error
        end
        it 'suceeds when :max option is an Integer' do
          expect{ subject.common_options_validator_helper( [:max], options_hash ) }.to raise_error
        end
        it 'suceeds when :max_size option is an Integer' do
          expect{ subject.common_options_validator_helper( [:max_size], options_hash ) }.to raise_error
        end
        it 'suceeds when :regexp option is a Regexp' do
          expect{ subject.common_options_validator_helper( [:regexp], options_hash ) }.to raise_error
        end
      end
    end
    
    context 'checking dependencies (check_dependencies)' do
      context 'for attributes that have subdefinitions' do
        it 'should call the single dependency check with a :required_if option' do
          subject.instance_variable_set(:@options, {:required_if => 'name' } )
          subject.should_receive(:check_dependency).and_return([])
          subject.check_dependencies( 'somerootvalue', 'somerootvalue' )
        end
        it 'should NOT call the single dependency check without a :required_if option' do
          subject.instance_variable_set(:@options, {} )
          subject.should_not_receive(:check_dependency)
          subject.check_dependencies( 'somerootvalue', 'somerootvalue' )
        end

        it 'should invoke check_dependencies_substructure ' do
          subject.instance_variable_set(:@sub_definition, 'not-nil' )
          subject.should_receive(:check_dependencies_substructure).and_return([])
          subject.check_dependencies( 'somerootvalue', 'somerootvalue' )
        end
        
        it 'should always accumulate the errors from both itself (due to its required_if) and the sub-elements' do
          toperror = ['toperror']
          suberrors = ['suberror1','suberror2']
          subject.instance_variable_set(:@options, {:required_if => 'name' } )
          subject.instance_variable_set(:@sub_definition, 'not-nil' )
          subject.should_receive(:check_dependency).and_return(toperror)
          subject.should_receive(:check_dependencies_substructure).and_return(suberrors)
          subject.check_dependencies( 'somerootvalue', 'somerootvalue' ).should == toperror + suberrors
        end
      end
    end
    
    context 'check_dependency (single condition for an attribute)' do
      context 'when there is a value loaded' do
        it 'suceeds since the requiredness dependency is fulfilled regardless of related attributes' do
           subject.check_dependency( 'name', 'foobar', 'it does not matter' ).should == []
        end
      end
      
      context 'for simple string conditions' do
        it 'should succeed if the dependent attribute is not defined either (nil)' do
          loaded_root = {'name_not_defined' => 'joe', 'other' => 123 }
          subject.check_dependency( 'name', nil, loaded_root ).should == []
        end
        it 'should return errors if the dependent attribute is defined (not nil)' do
          loaded_root = {'name' => 'joe', 'other' => 123 }
          subject.check_dependency( 'name', nil, loaded_root ).should_not == [] #TODO: lets be more explicit with the exected error string
        end
      end
      
      context 'for multi-element string conditions' do
        it 'should succeed if the dependent attribute is not defined either (nil)' do
          loaded_root = {'name' => 'joe', 'other' => 123 }
          subject.check_dependency( 'name.not.defined', nil, loaded_root ).should == []
        end
        it 'should return errors if the dependent attribute is defined (not nil)' do
          loaded_root = {'name' => { 'inside' => { 'hash' => 'joe' } }, 'other' => 123 }
          subject.check_dependency( 'name.inside.hash', nil, loaded_root ).should_not == [] #TODO: lets be more explicit with the exected error string
        end
      end
      context 'for Hash conditions' do
        it 'should succeed if the value of dependent attribute is not defined at all' do
          loaded_root = {'name' => { 'inside' => { 'nonexisting-hash' => 'nothing' } }, 'other' => 123 }
          subject.check_dependency( { 'name.inside.hash' => 'git' } , nil, loaded_root ).should == []
        end
        it 'should raise an error if more than 1 key in the condition spec is passed (could support that later on)' do
          expect{
            subject.check_dependency( { 'name1' => 'git' , 'name2' => '2' } , nil, 'unused' )
          }.to raise_error(Exception,/not more than 1 condition supported right now/)
        end
        context 'using string targets' do
          it 'should return errors if the value of dependent attribute is equal to the string in the condition' do
            loaded_root = {'name' => { 'inside' => { 'hash' => 'git' } }, 'other' => 123 }
            subject.check_dependency( { 'name.inside.hash' => 'git' } , nil, loaded_root ).should_not == []
          end
          it 'should succeed if the value of dependent attribute is not equal to the string in the condition' do
            loaded_root = {'name' => { 'inside' => { 'hash' => 'subversion' } }, 'other' => 123 }
            subject.check_dependency( { 'name.inside.hash' => 'git' } , nil, loaded_root ).should == []
          end
        end
        
        context 'using regexp targets' do
          it 'should return errors if the value of dependent attribute matches the regexp in the condition' do
            loaded_root = {'name' => { 'inside' => { 'hash' => 'git' } }, 'other' => 123 }
            subject.check_dependency( { 'name.inside.hash' => /it/ } , nil, loaded_root ).should_not == []
          end
          it 'should succeed if the value of dependent attribute doe NOT match the regexp in the condition' do
            loaded_root = {'name' => { 'inside' => { 'hash' => 'subversion' } }, 'other' => 123 }
            subject.check_dependency( { 'name.inside.hash' => /doesnotmatch/ } , nil, loaded_root ).should == []
          end
        end
        
        context 'using Proc targets' do
          it 'should return error if the proc in the condition returns true' do
            loaded_root = {'name' => { 'inside' => { 'hash' => 'git' } }, 'other' => 123 }
            subject.check_dependency( { 'name.inside.hash' => Proc.new{|val| val.is_a?(::String) && (val =~ /git/)!=nil } } , nil, loaded_root ).should_not == []
          end
          it 'should succeed if the proc in the condition returns false' do
            loaded_root = {'name' => { 'inside' => { 'hash' => 'subversion' } }, 'other' => 123 }
            subject.check_dependency( { 'name.inside.hash' => Proc.new{|val| val.is_a?(::String) && (val =~ /git/)!=nil } } , nil, loaded_root ).should == []
          end
        end
        
        
        
        
        
      end
      context 'for Proc/lambda conditions' do
        it 'is not implemented yet'
      end
      context 'for unsuported condition types' do
        it 'raises an error' do
          expect {
          subject.check_dependency( :invalid_condition , nil, 'unused' )
        }.to raise_error(Exception, /This type of condition definition is not currenty supported/)
        end
      end
    end
    
    context 'generating sub-contexts' do
      let(:parent_ctx) { }
      let(:subattr) { 'subattribute' }
      let(:generated_context) { subject.generate_subcontext(parent_ctx,subattr) }
      context 'when generating a subcontext from the root context' do
        let(:parent_ctx) { "" }
        it "does not prepend the separator" do
          generated_context.should == subattr
        end
      end
      context 'when generating a subcontext from another attribute' do
        let(:parent_ctx) { "parent_attribute" }
        it "does prepend the separator before the subcontext" do
          generated_context.should == "#{parent_ctx}#{Attributor::Attribute::SEPARATOR}#{subattr}"
        end
      end

      context 'when generating a subcontext from a nil parent' do
        let(:parent_ctx) { nil}
        it "does NOT prepend the separator as if it was the root context" do
          generated_context.should == subattr
        end
      end

    end
  end
  
  context 'documentation' do
    pending 'describe'
  end
end
