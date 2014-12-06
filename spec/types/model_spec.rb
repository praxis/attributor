require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Model do

  context 'class methods' do
    subject(:chicken) { Chicken }
    let(:context){ ["root","subattr"] }

    its(:native_type) { should eq(Chicken) }

    context '.example'  do
      subject(:chicken) { Chicken.example }

      let(:age_opts) { {options: Chicken.attributes[:age].options } }
      let(:age) { /\d{2}/.gen.to_i }

      context 'for a simple model' do
        it { should be_kind_of(Chicken) }

        context 'and attribute without :example option' do
          before do
            Attributor::Integer.should_receive(:example).with(kind_of(Array), age_opts).and_return(age)
          end

          its(:age) { should == age }
        end

        context 'and attribute with :example options' do
          before do
            Attributor::Integer.should_not_receive(:example) # due to lazy-evaluation of examples
            Attributor::String.should_not_receive(:example) # due to the :example option on the attribute
          end
          its(:email) { should =~ /\w+@.*\.example\.org/ }
        end

        context 'with given values' do
          let(:name) { 'Sir Clucksalot' }
          subject(:example) { Chicken.example(name: name)}

          its(:name) {should eq(name) }
        end
      end

      context 'generating multiple examples' do
        context 'without a context' do
          subject(:other_chicken) { Chicken.example }
          its(:attributes) { should_not eq(chicken.attributes) }
        end
        context 'with identical contexts' do
          let(:example_context) { 'some context' }
          let(:some_chicken) { Chicken.example(example_context) }
          subject(:another_chicken) { Chicken.example(example_context) }

          its(:attributes) { should eq(some_chicken.attributes) }
        end

      end

      context 'with attributes that are also models' do
        subject(:turducken) { Turducken.example }

        its(:attributes) { should have_key(:chicken) }
        its(:chicken) { should be_kind_of(Chicken)}
      end

      context 'with infinitely-expanding sub-attributes' do
        let(:model_class) do
          Class.new(Attributor::Model) do
            this = self 
            attributes do
              attribute :name, String
              attribute :child, this
            end
          end
        end

        subject(:example) { model_class.example }

        it 'terminates example generation at MAX_EXAMPLE_DEPTH' do
          # call .child on example MAX_EXAMPLE_DEPTH times
          terminal_child = Attributor::Model::MAX_EXAMPLE_DEPTH.times.inject(example) do |object, i|
            object.child
          end
          # after which .child will return nil
          terminal_child.child.should be(nil)
          # but simple attributes will be generated
          terminal_child.name.should_not be(nil)
        end


      end
    end


    context '.definition' do
      subject(:definition) { Chicken.definition }

      context '#attributes' do
        subject(:attributes) { Chicken.attributes }
        it { should have_key :age }
        it { should have_key :email }
      end
    end


    context '.load' do
      let(:age) { 1 }
      let(:email) { "cluck@example.org" }
      let(:hash) { {:age => age, :email => email} }

      subject(:model) { Chicken.load(hash) }

      context 'with an instance of the model' do
        it 'returns the instance' do
          Chicken.load(model).should be(model)
        end
      end

      context 'with a nil value' do
        it 'returns nil' do
          Chicken.load(nil).should be_nil
        end

        context 'with recurse: true' do
          subject(:turducken) { Turducken.load(nil, [], recurse: true) }

          it 'loads with default values' do
            turducken.name.should eq("Turkey McDucken")
            turducken.chicken.age.should be(1)
          end

        end
      end

      context 'with a JSON-serialized hash' do
        let(:context){ ['root','subattr'] }
        let(:expected_hash) { {"age" => age, "email" => email} }
        let(:json) { hash.to_json }
        before do
          Chicken.should_receive(:from_hash).
            with(expected_hash,context, recurse: false)
          JSON.should_receive(:parse).with(json).and_call_original
        end

        it 'deserializes and calls from_hash' do
          Chicken.load(json,context)
        end
      end

      context 'with an invalid JSON string' do
        let(:json) { "{'invalid'}" }

        it 'catches the error and reports it correctly' do
          JSON.should_receive(:parse).with(json).and_call_original
          expect {
            Chicken.load(json,context)
          }.to raise_error(Attributor::DeserializationError, /Error deserializing a String using JSON.*#{context.join('.')}/)
        end
      end


      context 'with an invalid object type' do
        it 'raises some sort of error' do
          expect {
            Chicken.load(Object.new, context)
          }.to raise_error(Attributor::IncompatibleTypeError, /Type Chicken cannot load values of type Object.*#{context.join('.')}/)
        end
      end

      context "with a hash" do
        context 'for a complete set of attributes' do
          it 'loads the given attributes' do
            model.age.should == age
            model.email.should == email
          end
        end

        context 'for a subset of attributes' do
          let(:hash) { Hash.new }

          it 'sets the defaults' do
            model.age.should == 1
            model.email.should == nil
          end
        end

        context 'for a superset of attributes' do
          let(:hash) { {"invalid_attribute" => "value"} }

          it 'raises an error' do
            expect {
              Chicken.load(hash, context)
            }.to raise_error(Attributor::AttributorException, /Unknown attributes.*#{context.join('.')}/)
          end
        end
      end



    end

  end


  context 'instance methods' do
    subject(:chicken) { Chicken.new }

    context '#respond_to?' do
      [:age, :email, :age=, :email=].each do |method|
        it { should respond_to(method) }
      end
    end

    context 'initialize' do

      subject(:chicken) { Chicken.new( attributes_data ) }
      context 'supports passing an initial hash object for attribute values' do
        let(:attributes_data){ {age: '1', email:'rooster@coup.com'} }
        it 'and sets them in loaded format onto the instance attributes' do
          Chicken.should_receive(:load).with(attributes_data).and_call_original
          attributes_data.keys.each do |attr_name|
            Chicken.attributes[attr_name].should_receive(:load).with(attributes_data[attr_name],instance_of(Array), recurse: false).and_call_original
          end
          subject.age.should be(1)
          subject.email.should be(attributes_data[:email])
        end
      end
      context 'supports passing a JSON encoded data object' do
        let(:attributes_hash){ {age: 1, email:'rooster@coup.com'} }
        let(:attributes_data){ JSON.dump(attributes_hash) }
          it 'and sets them in loaded format onto the instance attributes' do
            Chicken.should_receive(:load).with(attributes_data).and_call_original
            attributes_hash.keys.each do |attr_name|
              Chicken.attributes[attr_name].should_receive(:load).with(attributes_hash[attr_name],instance_of(Array), recurse: false).and_call_original
            end
            subject.age.should be(1)
            subject.email.should == attributes_hash[:email]
          end
        end
        context 'supports passing a native model for the data object' do
          let(:attributes_data){ Chicken.example }
          it 'sets a new instance pointing to the exact same attributes (careful about modifications!)' do
            attributes_data.attributes.each do |attr_name, attr_value|
              subject.send(attr_name).should be(attr_value)
            end
          end
        end
    end

    context 'getting and setting attributes' do
      context 'for valid attributes' do
        let(:age) { 1 }
        it 'gets and sets attributes' do
          chicken.age = age
          chicken.age.should == age
        end
      end

      context 'setting nil' do
        it 'assigns the default value if there is one' do
          chicken.age = nil
          chicken.age.should == 1
        end

        it 'sets the value to nil if there is no default' do
          chicken.email = nil
          chicken.email.should == nil
        end

      end

      context 'for unknown attributes' do
        it 'raises an exception' do
          expect {
            chicken.invalid_attribute =  'value'
          }.to raise_error(NoMethodError, /undefined method/)
        end
      end

      context 'for false attributes' do
        subject(:person) { Person.example(okay: false) }
        it 'properly memoizes the value' do
          person.okay.should be(false)
          person.okay.should be(false) # second call to ensure we hit the memoized value
        end
      end
    end

  end


  context 'validation' do
    context 'for simple models' do
      context 'that are valid' do
        subject(:chicken)  { Chicken.example }
        its(:validate) { should be_empty}
      end
      context 'that are invalid' do
        subject(:chicken) { Chicken.example(age: 150) }
        its(:validate) { should_not be_empty }
      end
    end

    context 'for models with circular sub-attributes' do
      context 'that are valid' do
        subject(:person) { Person.example }
        its(:validate) { should be_empty}
      end

      context 'that are invalid' do
        subject(:person) do
          # TODO: support this? Person.example(title: 'dude', address: {name: 'ME'} )

          obj = Person.example(title: 'dude')
          obj.address.state = 'ME'
          obj
        end

        its(:validate) { should have(2).items }

        it 'recursively-validates sub-attributes with the right context' do
          title_error, state_error = person.validate('person')
          title_error.should =~ /^Attribute person\.title:/
          state_error.should =~ /^Attribute person\.address\.state:/
        end

      end


    end
  end


  context '#dump' do


    context 'with circular references' do
      subject(:person) { Person.example }
      let(:output) { person.dump }

      it 'terminates' do
        expect {
          Person.example.dump
        }.to_not raise_error
      end

      it 'outputs "..." for circular references' do
        person.address.person.should be(person)
        output[:address][:person].should eq(Attributor::Model::CIRCULAR_REFERENCE_MARKER)
      end

    end

  end

  context 'extending' do
    subject(:model) do
      Class.new(Attributor::Model) do
        attributes do
          attribute :id, Integer
          attribute :timestamps do
            attribute :created_at, DateTime
          end
        end
      end
    end

    context 'adding a top-level attribute' do
      before do
        model.attributes do
          attribute :name, String
        end
      end

      it 'adds the attribute' do
        model.attributes.keys.should =~ [:id, :name, :timestamps]
      end

    end

    context 'adding to an inner-Struct' do
      before do
        model.attributes do
          attribute :timestamps, Struct do
            attribute :updated_at, DateTime
          end
        end
      end

      it 'merges with sub-attributes' do
        model.attributes[:timestamps].attributes.keys.should =~ [:created_at, :updated_at]
      end
    end


    context 'redefining an attribute' do
      before do
        model.attributes do
          attribute :id, String
        end
      end

      it 'works' do
        model.attributes[:id].type.should be(Attributor::String)
      end

    end

  end



end
