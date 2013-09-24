require_relative 'spec_helper'


describe Attributor::Attribute do

  let(:attribute_options) { Hash.new }
  let(:type) { AttributeType }
  subject(:attribute) { Attributor::Attribute.new(type, attribute_options) }

  let(:context) { "context" }
  let(:value) { "one" }

  context 'initialize' do
    its(:type) { should be type }
    its(:options) { should be attribute_options }

    it 'calls check_options!' do
      Attributor::Attribute.any_instance.should_receive(:check_options!)
      Attributor::Attribute.new(type, attribute_options)
    end

    context 'for anonymous types (aka Structs)' do
      let(:attribute_options) { {identity: 'id'} }

      before do
        Attributor.should_receive(:resolve_type).once.with(Struct,attribute_options, anything()).and_call_original
        Attributor.should_receive(:resolve_type).once.with(Integer,{}, nil).and_call_original
      end
      
      it 'generates the class' do
        thing = Attributor::Attribute.new(Struct, attribute_options) do
          attribute "id", Integer
        end
      end
      
    end
  end


  context 'describe' do
    let(:attribute_options) { {required: true, values:["one"], description: "something"} }
    let(:expected) { {type: type.name}.merge(attribute_options) }

    its(:describe) { should == expected }

    context 'for an anonymous type (aka: Struct)' do
      let(:attribute_options) { Hash.new }
      let(:attribute) do 
        Attributor::Attribute.new(Struct, attribute_options) do
          attribute "id", Integer
        end
      end
      subject(:description) { attribute.describe }


      it 'uses the name of the first non-anonymous ancestor' do
        description[:type].should == 'Struct'
      end

      it 'includes sub-attributes' do
        description[:attributes].should have_key('id')
      end

    end
  end


  context 'parse' do
    it 'loads and validates' do
      attribute.should_receive(:load).with(value).and_call_original
      attribute.should_receive(:validate).and_call_original

      attribute.parse(value)
    end

  end


  context 'checking options' do
    it 'has specs'
  end


  context 'example' do
    let(:example) { nil }
    let(:attribute_options) { {example: example} }

    context 'with nothing specified' do
      let(:attribute_options) { {} }
      before do
        type.should_receive(:example).and_return(example)
      end

      it 'defers to the type' do
        attribute.example.should be example
      end
    end


    context 'with a string' do
      let(:example) { "example" }

      its(:example) { should be example }
    end

    context 'with a regexp' do
      let(:example) { /\w+/ }


      it 'calls #gen on the regexp' do
        example.should_receive(:gen).and_call_original
        subject.example.should =~ example
      end

      context 'for a type with a non-String native_type' do
        let(:type) { IntegerAttributeType}
        let(:example) { /\d{5}/ }
        it 'coerces the example value properly' do
          example.should_receive(:gen).and_call_original
          type.should_receive(:load).and_call_original

          subject.example.should be_kind_of(type.native_type)
        end
      end
    end

    context 'with an array' do
      let(:example) { ["one", "two"] }
      it 'picks a random value' do
        example.should include subject.example
      end
    end

    context 'with an attribute that has the values option set' do
      let(:values) { ["one", "two"] }
      let(:attribute_options) { {values: values} }
      it 'picks a random value' do
        values.should include subject.example
      end

    end

    context 'deterministic examples' do
      let(:example) { /\w+/ }
      it 'can take a context to pre-seed the random number generator' do
        example_1 = subject.example('context')
        example_2 = subject.example('context')

        example_1.should eq example_2
      end

      it 'can take a context to pre-seed the random number generator' do
        example_1 = subject.example('context')
        example_2 = subject.example('different context')

        example_1.should_not eq example_2
      end

   end



  end

  context 'load' do
    let(:value) { 1 }

    it 'does not call type.load for nil values' do
      type.should_not_receive(:load)
      attribute.load(nil)
    end

    it 'delegates to type.load' do
      type.should_receive(:load).with(value)
      attribute.load(value)
    end


    context 'applying default values' do
      let(:default_value) { "default value" }
      let(:attribute_options) { {default: default_value} }

      subject(:result) { attribute.load(value) }

      context 'for nil' do
        let(:value) { nil }
        it { should == default_value}
      end


      context 'for a value that the type loads as nil' do
        let(:value) { "not nil"}
        before do
          type.should_receive(:load).and_return(nil)
        end
        it { should == default_value}
      end

    end

    context 'validating a value' do

      context '#validate' do
        context 'applying attribute options' do
          context ':required' do
            let(:attribute_options) { {required: true} }
            context 'with a nil value' do
              let(:value) { nil }
              it 'returns an error' do
                attribute.validate(value, context).first.should == 'Attribute context is required'
              end
            end
          end

          context ':values' do
            let(:values) { ['one','two'] }
            let(:attribute_options) { {values: values} }
            let(:value) { nil }

            subject(:errors) { attribute.validate(value, context)}

            context 'with a value that is allowed' do
              let(:value) { "one" }
              it 'returns no errors' do
                errors.should be_empty
              end
            end

            context 'with a value that is not allowed' do
              let(:value) { "three" }
              it 'returns an error indicating the problem' do
                errors.first.should =~ /is not within the allowed values/
              end

            end
          end


        end

        it 'calls the right validate_X methods?' do
          attribute.should_receive(:validate_type).with(value, context).and_call_original
          attribute.should_not_receive(:validate_dependency)
          type.should_receive(:validate).and_call_original

          attribute.validate(value, context)
        end

      end

      context '#validate_type' do
        subject(:errors) { attribute.validate_type(value, context)}

        context 'with a value of the right type' do
          let(:value) { "one" }
          it 'returns no errors' do
            errors.should be_empty
          end
        end

        context 'with a value of a value different than the native_type' do
          let(:value) { 1 }

          it 'returns errors' do
            errors.should_not be_empty
            errors.first.should  =~ /is of the wrong type/
          end

        end


      end

      context '#validate_dependency' do
        let(:key) { "$.instance.ssh_key.name" }

        let(:attribute_options) { {required_if: key} }

        let(:ssh_key) { double("ssh_key", name:value) }
        let(:instance) { double("instance", ssh_key:ssh_key) }

        before { Attributor::AttributeResolver.current.register('instance', instance) }

        subject(:errors) { attribute.validate_dependency('') }

        context 'for a simple dependency without a condition' do
          context 'that is satisfied' do
            it { should be_empty }
          end

          context 'that is missing' do
            let(:value) { nil }
            it { should_not be_empty }
          end
        end

        context 'with a dependency that has a condition' do
          let(:value) { "default_ssh_key_name" }
          subject(:errors) { attribute.validate_dependency('') }

          context 'that is satisfied' do
            let(:attribute_options) { {required_if: {key => /default/} } }
            it { should be_empty }
          end

          context 'that is not satisfied' do
            let(:attribute_options) { {required_if: {key => /other/} } }
            it { should_not be_empty }
          end

          context 'for an attribute that is missing' do
            let(:attribute_options) { {required_if: {key => /default/} } }
            let(:ssh_key) { double("ssh_key", name: nil) }

            it { should_not be_empty }
          end
        end

      end

    end




    context 'for an attribute for a subclass of Model' do
      let(:type) { Chicken }
      let(:type_options) { Chicken.definition.options }

      subject(:attribute) { Attributor::Attribute.new(type, attribute_options) }

      it 'has attributes' do
        attribute.attributes.should == type.definition.attributes
      end

      it 'has compiled_definition' do
        attribute.compiled_definition.should == type.definition
      end


      it 'merges its options with those of the compiled_definition' do
        attribute.options.should == attribute_options.merge(type_options)
      end


      it 'describe handles sub-attributes nicely' do
        describe = attribute.describe

        describe[:type].should == type.name
        attribute_options.each do |k,v|
          describe[k].should == v
        end

        type_options.each do |k,v|
          describe[k].should == v
        end

        attribute.attributes.each do |name, attr|
          describe[:attributes].should have_key(name)
        end

      end

      it 'supports deterministic examples' do
        example_1 = attribute.example("Chicken context")
        example_2 = attribute.example("Chicken context")

        example_1.attributes.should eq(example_2.attributes)
      end

      context '#validate' do
        let(:chicken) { Chicken.example }
        let(:type_attributes) { type.definition.attributes }


        let(:email_validation_response) { [] }
        let(:age_validation_response) { [] }

        before do
          type_attributes["email"].should_receive(:validate).
            with(chicken.get('email'), 'email').and_return(email_validation_response)
          type_attributes["age"].should_receive(:validate).
            with(chicken.get('age'), 'age').and_return(age_validation_response)
        end

        it 'validates sub-attributes' do
          errors = attribute.validate(chicken)
          errors.should be_empty
        end

        context 'with a failing validation' do
          let(:email_validation_response) { ["Chicken has invalid email"] }
          let(:age_validation_response) { ["Chicken is too old"] }

          it 'collects sub-attribute validation errors' do
            errors = attribute.validate(chicken)
            errors.should =~ (age_validation_response | email_validation_response)
          end
        end

      end


      context '#validate_dependency' do
        let(:type) { Duck }

        subject(:errors) { attribute.validate(duck, 'duck') }

        before do
          Attributor::AttributeResolver.current.register('duck', duck)
        end

        context 'for a simple dependency' do
          let(:duck) do
            d = Duck.new
            d.set 'age', 1
            d.set 'name', 'Donald'
            d
          end

          context 'that is satisfied' do
            before do
              duck.set 'email', /[:email:]/.gen
            end
            it { should be_empty }
          end
          context 'that is unsatisfied' do
            it { should_not be_empty }
            its(:first) { should =~ /fails to satisfy dependency/ }
          end
        end


        context 'for a complex dependency' do
          let(:duck) do
            d = Duck.new
            d.set 'name', 'Daffy'
            d.set 'email', 'daffy@darkwing.uoregon.edu' # he's a duck,get it?
            d
          end

          context 'that is satisfied' do
            before do
              duck.set 'age', 1
            end
            it { should be_empty }
          end

          context 'that is unsatisfied' do
            it { should_not be_empty }
            its(:first) { should =~ /fails to satisfy dependency/ }
          end

        end

      end

    end





  end

end


