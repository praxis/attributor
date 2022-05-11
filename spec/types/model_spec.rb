require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Model do
  subject(:chicken) { Chicken }

  # TODO: should move most of these specs to hash spec

  context 'attributes' do
    context 'with an exception from the definition block' do
      subject(:broken_model) do
        Class.new(Attributor::Model) do
          attributes do
            raise 'sorry :('
          end
        end
      end

      it 'throws original exception upon first run' do
        expect do
          broken_model.attributes
        end.to raise_error(RuntimeError, 'sorry :(')
      end

      it 'throws InvalidDefinition for subsequent access' do
        begin
          broken_model.attributes
        rescue
          nil
        end

        expect do
          broken_model.attributes
        end.to raise_error(Attributor::InvalidDefinition)
      end

      it 'throws for any attempts at using of an instance of it' do
        begin
          broken_model.attributes
        rescue
          nil
        end

        instance = broken_model.new
        expect do
          instance.name
        end.to raise_error(Attributor::InvalidDefinition)
      end
    end
  end

  context 'class methods' do
    let(:context) { %w(root subattr) }

    its(:native_type) { should eq(Chicken) }

    context '.example'  do
      subject(:chicken) { Chicken.example }

      let(:age_opts) { { options: Chicken.attributes[:age].options } }
      let(:age) { /\d{2}/.gen.to_i }

      context 'for a simple model' do
        it { should be_kind_of(Chicken) }

        context 'and attribute without :example option' do
          before do
            expect(Attributor::Integer).to receive(:example).with(kind_of(Array), age_opts).and_return(age)
          end

          its(:age) { should eq age }
        end

        context 'and attribute with :example options' do
          before do
            expect(Attributor::Integer).not_to receive(:example) # due to lazy-evaluation of examples
            expect(Attributor::String).not_to receive(:example) # due to the :example option on the attribute
          end
          its(:email) { should match(/\w+@.*\.example\.org/) }
        end

        context 'with given values' do
          let(:name) { 'Sir Clucksalot' }
          subject(:example) { Chicken.example(name: name) }

          its(:name) { should eq(name) }
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
        its(:chicken) { should be_kind_of(Chicken) }
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
          terminal_child = Attributor::Model::MAX_EXAMPLE_DEPTH.times.inject(example) do |object, _i|
            object.child
          end
          # after which .child will return nil
          expect(terminal_child.child).to be(nil)
          # but simple attributes will be generated
          expect(terminal_child.name).not_to be(nil)
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
      let(:email) { 'cluck@example.org' }
      let(:hash) { { age: age, email: email } }

      subject(:model) { Chicken.load(hash) }

      context 'with an instance of the model' do
        it 'returns the instance' do
          expect(Chicken.load(model)).to be(model)
        end
      end

      context 'with a nil value' do
        it 'returns nil' do
          expect(Chicken.load(nil)).to be_nil
        end

        context 'with recurse: true' do
          subject(:turducken) { Turducken.load(nil, [], recurse: true) }

          it 'loads with default values' do
            expect(turducken.name).to eq('Turkey McDucken')
            expect(turducken.chicken.age).to be(1)
          end
        end
      end

      context 'with a JSON-serialized hash' do
        let(:context) { %w(root subattr) }
        let(:expected_hash) { { 'age' => age, 'email' => email } }
        let(:json) { hash.to_json }
        before do
          expect(Chicken).to receive(:from_hash)
            .with(expected_hash, context, recurse: false)
          expect(JSON).to receive(:parse).with(json).and_call_original
        end

        it 'deserializes and calls from_hash' do
          Chicken.load(json, context)
        end
      end

      context 'with an invalid JSON string' do
        let(:json) { "{'invalid'}" }

        it 'catches the error and reports it correctly' do
          expect(JSON).to receive(:parse).with(json).and_call_original
          expect do
            Chicken.load(json, context)
          end.to raise_error(Attributor::DeserializationError,
                             /Error deserializing a String using JSON.*#{context.join('.')}/)
        end
      end

      context 'with an invalid object type' do
        it 'raises some sort of error' do
          expect do
            Chicken.load(Object.new, context)
          end.to raise_error(Attributor::IncompatibleTypeError,
                             /Type Chicken cannot load values of type Object.*#{context.join('.')}/)
        end
      end

      context 'with an instance of different model' do
        it 'raises some sort of error' do
          expect do
            turducken = Turducken.example
            Chicken.load(turducken, context)
          end.to raise_error(Attributor::AttributorException, /Unknown key received/)
        end
      end

      context 'with a hash' do
        context 'for a complete set of attributes' do
          it 'loads the given attributes' do
            expect(model.age).to eq age
            expect(model.email).to eq email
          end
        end

        context 'for a subset of attributes' do
          let(:hash) { Hash.new }

          it 'sets the defaults' do
            expect(model.age).to eq 1
            expect(model.email).to be nil
          end
        end

        context 'for a superset of attributes' do
          let(:hash) { { 'invalid_attribute' => 'value' } }

          it 'raises an error' do
            expect do
              Chicken.load(hash, context)
            end.to raise_error(Attributor::AttributorException, /Unknown key received/)
            # raise_error(Attributor::AttributorException, /Unknown attributes.*#{context.join('.')}/)
          end
        end

        context 'loading with default values' do
          let(:reference) { Post }
          let(:options) { { reference: reference } }

          let(:attribute_definition) do
            proc do
              attribute :title
              attribute :tags, default: %w(stuff things)
            end
          end

          let(:struct) { Attributor::Struct.construct(attribute_definition, options) }

          let(:data) { { title: 'my post' } }

          subject(:loaded) { struct.load(data) }

          it 'validates' do
            expect(loaded.validate).to be_empty
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
      subject(:chicken) { Chicken.new(attributes_data) }
      context 'supports passing an initial hash object for attribute values' do
        let(:attributes_data) { { age: '1', email: 'rooster@coup.com' } }
        it 'and sets them in loaded format onto the instance attributes' do
          expect(Chicken).to receive(:load).with(attributes_data).and_call_original
          attributes_data.keys.each do |attr_name|
            expect(Chicken.attributes[attr_name]).to receive(:load)
              .with(attributes_data[attr_name], instance_of(Array), recurse: false)
              .and_call_original
          end
          expect(subject.age).to be(1)
          expect(subject.email).to be(attributes_data[:email])
        end
      end
      context 'supports passing a JSON encoded data object' do
        let(:attributes_hash) { { age: 1, email: 'rooster@coup.com' } }
        let(:attributes_data) { JSON.dump(attributes_hash) }
        it 'and sets them in loaded format onto the instance attributes' do
          expect(Chicken).to receive(:load).with(attributes_data).and_call_original
          attributes_hash.keys.each do |attr_name|
            expect(Chicken.attributes[attr_name]).to receive(:load)
              .with(attributes_hash[attr_name], instance_of(Array), recurse: false)
              .and_call_original
          end
          expect(subject.age).to be(1)
          expect(subject.email).to eq attributes_hash[:email]
        end
      end
      context 'supports passing a native model for the data object' do
        let(:attributes_data) { Chicken.example }
        it 'sets a new instance pointing to the exact same attributes (careful about modifications!)' do
          attributes_data.attributes.each do |attr_name, attr_value|
            expect(subject.send(attr_name)).to be(attr_value)
          end
        end
      end
    end

    context 'getting and setting attributes' do
      context 'for valid attributes' do
        let(:age) { 1 }
        it 'gets and sets attributes' do
          chicken.age = age
          expect(chicken.age).to eq age
        end
      end

      context 'setting nil' do
        it 'assigns the default value if there is one' do
          chicken.age = nil
          expect(chicken.age).to eq 1
        end

        it 'sets the value to nil if there is no default' do
          chicken.email = nil
          expect(chicken.email).to be nil
        end
      end

      context 'for unknown attributes' do
        it 'raises an exception' do
          expect do
            chicken.invalid_attribute = 'value'
          end.to raise_error(NoMethodError, /undefined method/)
        end
      end

      context 'for false attributes' do
        subject(:person) { Person.example(okay: false) }
        it 'properly memoizes the value' do
          expect(person.okay).to be(false)
          expect(person.okay).to be(false) # second call to ensure we hit the memoized value
        end
      end
    end
  end

  context 'validation' do
    context 'for simple models' do
      context 'that are valid' do
        subject(:chicken) { Chicken.example }
        its(:validate) { should be_empty }
      end
      context 'that are invalid' do
        subject(:chicken) { Chicken.example(age: 150) }
        its(:validate) { should_not be_empty }
      end
    end

    context 'for models using the "requires" DSL' do
      subject(:address) { Address.load({state: 'CA'}) }
      its(:validate) { should_not be_empty }
      its(:validate) { should include 'Attribute $.key(:name) is required.' }
    end
    context 'for models with non-nullable attributes' do
      subject(:address) { Address.load({name: nil, state: nil}) }
      its(:validate) { should_not be_empty }
      its(:validate) { should include 'Attribute $.state is not nullable.' } # name is nullable
    end
    context 'for models with circular sub-attributes' do
      context 'that are valid' do
        subject(:person) { Person.example }
        its(:validate) { should be_empty }
      end

      context 'that are both invalid' do
        subject(:person) { Person.load({name: 'Joe', title: 'dude', okay: true}) }
        let(:address) { Address.load({name: '1 Main St', state: 'ME'}) }
        before do
          person.address = address
          address.person = person
        end

        its(:validate) { should have(2).items }

        it 'recursively-validates sub-attributes with the right context' do
          title_error, state_error = person.validate('person')
          expect(title_error).to match(/^Attribute person\.title:/)
          expect(state_error).to match(/^Attribute person\.address\.state:/)
        end
      end
    end
  end

  context '#dump' do
    context 'with circular references' do
      subject(:person) { Person.example }
      let(:output) { person.dump }

      it 'terminates' do
        expect do
          Person.example.dump
        end.to_not raise_error
      end

      it 'outputs "..." for circular references' do
        expect(person.address.person).to be(person)
        expect(output[:address][:person]).to eq(Attributor::Model::CIRCULAR_REFERENCE_MARKER)
      end

      it 'passes kwargs' do
        person.class.attributes.values.each do |attr|
          expect(attr).to receive(:dump).with(
            anything,
            context: anything,
            custom_arg: :custom_value
          )
        end
        person.dump(custom_arg: :custom_value)
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
        expect(model.attributes.keys).to match_array [:id, :name, :timestamps]
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
        expect(model.attributes[:timestamps].attributes.keys).to match_array [:created_at, :updated_at]
      end
    end

    context 'for collections of models' do
      let(:attributes_block) do
        proc do
          attribute :neighbors, required: true do
            attribute :name, required: true
            attribute :age, Integer
          end
        end
      end
      subject(:struct) { Attributor::Struct.construct(attributes_block, reference: Cormorant) }

      it 'supports defining sub-attributes using the proper reference' do
        expect(struct.attributes[:neighbors].options[:required]).to be true
        expect(struct.attributes[:neighbors].options[:null]).to be false
        expect(struct.attributes[:neighbors].type.member_attribute.type.attributes.keys).to match_array [:name, :age]

        name_options = struct.attributes[:neighbors].type.member_attribute.type.attributes[:name].options
        expect(name_options[:required]).to be true
        expect(name_options[:description]).to eq 'Name of the Cormorant'
      end
    end

    context 'redefining an attribute' do
      context 'for simple types' do
        before do
          model.attributes do
            attribute :id, String
          end
        end

        it 'updates the type properly' do
          expect(model.attributes[:id].type).to be(Attributor::String)
        end
      end
    end
  end

  context 'with no defined attributes' do
    let(:model_class) do
      Class.new(Attributor::Model) do
        attributes do
        end
      end
    end

    subject(:example) { model_class.example }

    its(:attributes) { should be_empty }

    it 'dumps as an empty hash' do
      expect(example.dump).to eq({})
    end
  end

  context '#to_hash' do
    let(:model_type) do
      Class.new(Attributor::Model) do
        attributes do
          attribute :name, String
          attribute :subkey do
            attribute :id, Integer
          end
        end
      end
    end

    subject { model_type.new(name: 'Praxis', subkey: { id: 1 }).to_hash }
    it 'returns the top keys as a hash' do
      expect(subject.keys).to eq([:name, :subkey])
    end
    it 'does not recurse down' do
      expect(subject[:subkey]).to be_kind_of Attributor::Struct
    end
  end

end
