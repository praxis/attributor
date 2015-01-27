require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Attributor::Attribute do

  let(:attribute_options) { Hash.new }
  let(:type) { AttributeType }

  subject(:attribute) { Attributor::Attribute.new(type, attribute_options) }

  let(:context) { ["context"] }
  let(:value) { "one" }

  context 'initialize' do
    its(:type) { should be type }
    its(:options) { should be attribute_options }

    it 'calls check_options!' do
      Attributor::Attribute.any_instance.should_receive(:check_options!)
      Attributor::Attribute.new(type, attribute_options)
    end

    context 'for anonymous types (aka Structs)' do
      before do
        Attributor.should_receive(:resolve_type).once.with(Struct,attribute_options, anything()).and_call_original
      end

      it 'generates the class' do
        thing = Attributor::Attribute.new(Struct, attribute_options) do
          attribute :id, Integer
        end
      end

    end

  end

  context '==' do
    let(:other_attribute) { Attributor::Attribute.new(type, attribute_options) }
    it { should == other_attribute}
  end

  context 'describe' do
    let(:attribute_options) { {:required => true, :values => ["one"], :description => "something", :min => 0} }
    let(:expected) do
      h = {:type => {:name => type.name} }
      common = attribute_options.select{|k,v| Attributor::Attribute::TOP_LEVEL_OPTIONS.include? k }
      h.merge!( common )
      h[:options] = {:min => 0 }
      h
    end


    its(:describe) { should == expected }

    context 'with example options' do
      let(:attribute_options) { {:description=> "something", :example => "ex_def"} }
      its(:describe) { should have_key(:example_definition) }
      its(:describe) { should_not have_key(:example) }
      it 'should have the example value in the :example_definition key' do
        subject.describe[:example_definition].should == "ex_def"
      end
    end

    context 'for an anonymous type (aka: Struct)' do
      let(:attribute_options) { Hash.new }
      let(:attribute) do
        Attributor::Attribute.new(Struct, attribute_options) do
          attribute :id, Integer
        end
      end


      subject(:description) { attribute.describe }


      it 'uses the name of the first non-anonymous ancestor' do
        description[:type][:name].should == 'Struct'
      end

      it 'includes sub-attributes' do
        description[:type][:attributes].should have_key(:id)
      end

    end
  end


  context 'parse' do
    let(:loaded_object){ double("I'm loaded") }
    it 'loads and validates' do
      attribute.should_receive(:load).with(value,Attributor::DEFAULT_ROOT_CONTEXT).and_return(loaded_object)
      attribute.should_receive(:validate).with(loaded_object,Attributor::DEFAULT_ROOT_CONTEXT).and_call_original

      attribute.parse(value)
    end
  end


  context 'checking options' do
    it 'raises for invalid options' do
      expect {
        Attributor::Attribute.new(Integer, unknown_opt: true)
      }.to raise_error(/unsupported option/)
    end

    it 'has a spec that we try to validate the :default value' do
      expect {
        Attributor::Attribute.new(Integer, default: "not an okay integer")
      }.to raise_error(/Default value doesn't have the correct attribute type/)
    end

  end


  context 'example' do
    let(:example) { nil }
    let(:attribute_options) { {:example => example} }

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


    context 'with a proc' do
      context 'with one argument' do
        let(:example) { lambda { |obj| 'ok' } }
        let(:some_object) { Object.new }

        before do
          example.should_receive(:call).with(some_object).and_call_original
        end

        it 'passes any given parent through to the example proc' do
          subject.example(nil, parent: some_object).should == 'ok'
        end
      end

      context 'with two arguments' do
        let(:example) { lambda { |obj, context| "#{context} ok" } }
        let(:some_object) { Object.new }
        let(:some_context) { ['some_context'] }

        before do
          example.should_receive(:call).with(some_object, some_context).and_call_original
        end

        it 'passes any given parent through to the example proc' do
          subject.example(some_context, parent: some_object).should == "#{some_context} ok"
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
      let(:attribute_options) { {:values => values} }
      it 'picks a random value' do
        values.should include subject.example
      end

    end

    context 'deterministic examples' do
      let(:example) { /\w+/ }
      it 'can take a context to pre-seed the random number generator' do
        example_1 = subject.example(['context'])
        example_2 = subject.example(['context'])

        example_1.should eq example_2
      end

      it 'can take a context to pre-seed the random number generator' do
        example_1 = subject.example(['context'])
        example_2 = subject.example(['different context'])

        example_1.should_not eq example_2
      end

    end
  end

  context 'load' do
    let(:context){ ['context'] }
    let(:value) { '1' }

    it 'delegates to type.load' do
      type.should_receive(:load).with(value,context, {})
      attribute.load(value,context)
    end

    it 'passes options to type.load' do
      type.should_receive(:load).with(value, context, foo: 'bar')
      attribute.load(value, context, foo: 'bar')
    end

    context 'applying default values' do
      let(:value) { nil }
      let(:default_value) { "default value" }
      let(:attribute_options) { {:default => default_value} }

      subject(:result) { attribute.load(value) }

      context 'for nil' do
        it { should == default_value}
      end

      context 'for false' do
        let(:type) { Attributor::Boolean }
        let(:default_value) { false }
        it { should == default_value}

      end
      
      context 'for a Proc-based default value' do
        let(:context){ ["$"] }
        subject(:result){ attribute.load(value,context) }


        context 'with no arguments arguments' do
          let(:default_value) { proc { "no_params" } }
          it { should == default_value.call }
        end
        
        context 'with 1 argument (the parent)' do
          let(:default_value) { proc {|parent| "parent is fake: #{parent.class}" } }
          it { should == "parent is fake: Attributor::FakeParent" }
        end
        
        context 'with 2 argument (the parent and the contents)' do
          let(:default_value) { proc {|parent,context| "parent is fake: #{parent.class} and context is: #{context}" } }
          it { should == "parent is fake: Attributor::FakeParent and context is: [\"$\"]"}
        end
        
        context 'which attempts to use the parent (which is not supported for the moment)' do
          let(:default_value) { proc {|parent| "any parent method should spit out warning: [#{parent.something}]" } }
          it "should output a warning" do
            begin 
              old_verbose, $VERBOSE = $VERBOSE, nil
              Kernel.should_receive(:warn).and_call_original
              attribute.load(value,context).should == "any parent method should spit out warning: []"
            ensure
              $VERBOSE = old_verbose
            end
          end
        end
      end
    end

    context 'validating a value' do

      context '#validate' do
        context 'applying attribute options' do
          context ':required' do
            let(:attribute_options) { {:required => true} }
            context 'with a nil value' do
              let(:value) { nil }
              it 'returns an error' do
                attribute.validate(value, context).first.should == 'Attribute context is required'
              end
            end
          end

          context ':values' do
            let(:values) { ['one','two'] }
            let(:attribute_options) { {:values => values} }
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

      context '#validate_missing_value' do
        let(:key) { "$.instance.ssh_key.name" }
        let(:value) { /\w+/.gen }

        let(:attribute_options) { {:required_if => key} }

        let(:ssh_key) { double("ssh_key", :name => value) }
        let(:instance) { double("instance", :ssh_key => ssh_key) }

        before { Attributor::AttributeResolver.current.register('instance', instance) }

        let(:attribute_context) { ['$','params','key_material'] }
        subject(:errors) { attribute.validate_missing_value(attribute_context) }


        context 'for a simple dependency without a predicate' do
          context 'that is satisfied' do
            it { should_not be_empty }
          end

          context 'that is missing' do
            let(:value) { nil }
            it { should be_empty }
          end
        end

        context 'with a dependency that has a predicate' do
          let(:value) { "default_ssh_key_name" }
          #subject(:errors) { attribute.validate_missing_value('') }

          context 'where the target attribute exists, and matches the predicate' do
            let(:attribute_options) { {:required_if => {key => /default/} } }

            it { should_not be_empty }

            its(:first) { should =~ /Attribute #{Regexp.quote(Attributor.humanize_context( attribute_context ))} is required when #{Regexp.quote(key)} matches/ }
          end

          context 'where the target attribute exists, but does not match the predicate' do
            let(:attribute_options) { {:required_if => {key => /other/} } }

            it { should be_empty }
          end

          context 'where the target attribute does not exist' do
            let(:attribute_options) { {:required_if => {key => /default/} } }
            let(:ssh_key) { double("ssh_key", :name => nil) }

            it { should be_empty }
          end
        end

      end

    end


    context 'for an attribute for a subclass of Model' do
      let(:type) { Chicken }
      let(:type_options) { Chicken.options }

      subject(:attribute) { Attributor::Attribute.new(type, attribute_options) }

      it 'has attributes' do
        attribute.attributes.should == type.attributes
      end

      #it 'has compiled_definition' do
      #  attribute.compiled_definition.should == type.definition
      #end


      it 'merges its options with those of the compiled_definition' do
        attribute.options.should == attribute_options.merge(type_options)
      end

      it 'describe handles sub-attributes nicely' do
        describe = attribute.describe(false)

        describe[:type][:name].should == type.name
        common_options = attribute_options.select{|k,v| Attributor::Attribute.TOP_LEVEL_OPTIONS.include? k }
        special_options = attribute_options.reject{|k,v| Attributor::Attribute.TOP_LEVEL_OPTIONS.include? k }
        common_options.each do |k,v|
          describe[k].should == v
        end
        special_options.each do |k,v|
          describe[:options][k].should == v
        end
        type_options.each do |k,v|
          describe[:options][k].should == v
        end


        attribute.attributes.each do |name, attr|
          describe[:type][:attributes].should have_key(name)
        end

      end

      it 'supports deterministic examples' do
        example_1 = attribute.example(["Chicken context"])
        example_2 = attribute.example(["Chicken context"])

        example_1.attributes.should eq(example_2.attributes)
      end

      context '#validate' do
        let(:chicken) { Chicken.example }
        let(:type_attributes) { type.attributes }

        it 'validates sub-attributes' do
          errors = attribute.validate(chicken)
          errors.should be_empty
        end

        context 'with a failing validation' do
          subject(:chicken) { Chicken.example(age: 150, email: "foo") }
          let(:email_validation_response) { ["$.email value \(#{chicken.email}\) does not match regexp (/@/)"] }
          let(:age_validation_response) { ["$.age value \(#{chicken.age}\) is larger than the allowed max (120)"] }

          it 'collects sub-attribute validation errors' do
            errors = attribute.validate(chicken)
            errors.should =~ (age_validation_response | email_validation_response)
          end
        end

      end


      context '#validate_missing_value' do
        let(:type) { Duck }
        let(:attribute_name) { nil }
        let(:attribute) { Duck.attributes[attribute_name] }

        let(:attribute_context) { ['$','duck',"#{attribute_name}"] }
        subject(:errors) { attribute.validate_missing_value(attribute_context) }

        before do
          Attributor::AttributeResolver.current.register('duck', duck)
        end

        context 'for a dependency with no predicate' do
          let(:attribute_name) { :email }

          let(:duck) do
            d = Duck.new
            d.age = 1
            d.name = 'Donald'
            d
          end

          context 'where the target attribute exists, and matches the predicate' do
            it { should_not be_empty }
            its(:first) { should == "Attribute $.duck.email is required when name (for $.duck) is present." }
          end
          context 'where the target attribute does not exist' do
            before do
              duck.name = nil
            end
            it { should be_empty }
          end
        end


        context 'for a dependency with a predicate' do
          let(:attribute_name) { :age }

          let(:duck) do
            d = Duck.new
            d.name = 'Daffy'
            d.email = 'daffy@darkwing.uoregon.edu' # he's a duck,get it?
            d
          end

          context 'where the target attribute exists, and matches the predicate' do
            it { should_not be_empty }
            its(:first) { should =~ /Attribute #{Regexp.quote('$.duck.age')} is required when name #{Regexp.quote('(for $.duck)')} matches/ }
          end

          context 'where the target attribute exists, and does not match the predicate' do
            before do
              duck.name = 'Donald'
            end
            it { should be_empty }
          end

          context 'where the target attribute does not exist' do
            before do
              duck.name = nil
            end
            it { should be_empty }
          end

        end

      end

    end
  end

  context 'for a Collection' do
    context 'of non-Model (or Struct) type' do
      let(:member_type) { Attributor::Integer }
      let(:type) { Attributor::Collection.of(member_type)}
      let(:member_options) { {:max => 10} }
      let(:attribute_options) { {:member_options => member_options} }

      context 'the member_attribute of that type' do
        subject(:member_attribute) { attribute.type.member_attribute }

        it { should be_kind_of(Attributor::Attribute)}
        its(:type) { should be(member_type) }
        its(:options) { should eq(member_options) }
      end

      context "working with members" do
        let(:values) { ['1',2,12] }

        it 'loads' do
          attribute.load(values).should =~ [1,2,12]
        end

        it 'validates' do
          errors = attribute.validate(values)
          errors.should_not be_empty
          errors[0].should =~ /of the wrong type/
          errors[1].should =~ /value \(12\) is larger/
        end


      end


    end

    context 'of a Model (or Struct) type' do
      subject(:attribute) { Attributor::Attribute.new(type, attribute_options, &attribute_block)  }

      let(:attribute_block) { Proc.new{ attribute :angry , required: true } }
      let(:attribute_options) { {reference: Chicken, member_options: member_options} }
      let(:member_type) { Attributor::Struct }
      let(:type) { Attributor::Collection.of(member_type) }
      let(:member_options) { {} }


      context 'the member_attribute of that type' do
        subject(:member_attribute) { attribute.type.member_attribute }
        it { should be_kind_of(Attributor::Attribute)}
        its(:options) { should eq(member_options.merge(reference: Chicken, identity: :email)) }
        its(:attributes) { should have_key :angry }
        it 'inherited the type and options from the reference' do
          member_attribute.attributes[:angry].type.should be(Chicken.attributes[:angry].type)
          member_attribute.attributes[:angry].options.should eq(Chicken.attributes[:angry].options.merge(required: true))
        end
      end

    end
  end

end
