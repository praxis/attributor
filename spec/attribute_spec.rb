require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::Attribute do
  let(:attribute_options) { Hash.new }
  let(:type) { Attributor::String }

  subject(:attribute) { Attributor::Attribute.new(type, attribute_options) }

  let(:context) { ['context'] }
  let(:value) { 'one' }

  context 'initialize' do
    its(:type) { should be type }
    its(:options) { should be attribute_options }

    it 'calls check_options!' do
      expect_any_instance_of(Attributor::Attribute).to receive(:check_options!)
      Attributor::Attribute.new(type, attribute_options)
    end

    context 'for anonymous types (aka Structs)' do
      before do
        expect(Attributor).to receive(:resolve_type).once.with(Struct, attribute_options, anything).and_call_original
      end

      it 'generates the class' do
        Attributor::Attribute.new(Struct, attribute_options) do
          attribute :id, Integer
        end
      end
    end
  end

  context '==' do
    let(:other_attribute) { Attributor::Attribute.new(type, attribute_options) }
    it { should eq other_attribute }
  end

  context 'describe' do
    let(:attribute_options) { { required: true, values: ['one'], description: 'something', min: 0 } }
    let(:expected) do
      h = { type: { name: 'String', id: type.id, family: type.family } }
      common = attribute_options.select { |k, _v| Attributor::Attribute::TOP_LEVEL_OPTIONS.include? k }
      h.merge!(common)
      h[:options] = { min: 0 }
      h
    end

    its(:describe) { should eq expected }

    context 'with example options' do
      let(:attribute_options) { { description: 'something', example: 'ex_def' } }
      its(:describe) { should have_key(:example_definition) }
      its(:describe) { should_not have_key(:example) }
      it 'should have the example value in the :example_definition key' do
        expect(subject.describe[:example_definition]).to eq 'ex_def'
      end
    end

    context 'with custom_data' do
      let(:custom_data) { { loggable: true, visible_in_ui: false } }
      let(:attribute_options) { { custom_data: custom_data } }
      its(:describe) { should have_key(:custom_data) }

      it 'keep the custom data attribute' do
        expect(subject.describe[:custom_data]).to eq custom_data
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
        expect(description[:type][:name]).to eq 'Struct'
      end

      it 'includes sub-attributes' do
        expect(description[:type][:attributes]).to have_key(:id)
      end
    end

    context 'with an example' do
      let(:attribute_options) { {} }
      let(:example) { attribute.example }
      subject(:described) { attribute.describe(false, example: example) }

      context 'using a simple terminal type' do
        let(:type) { String }
        its(:keys) { should include(:example) }
        it 'should have the passed example value' do
          expect(described).to have_key(:example)
          expect(described[:example]).to eq(example)
        end
        it 'should have removed the example from the :type' do
          expect(described[:type]).not_to have_key(:example)
        end
      end

      context 'using a complex type' do
        let(:type) { Cormorant }
        its(:keys) { should_not include(:example) }

        it 'Should see examples in the right places, depending on leaf/no-leaf types' do
          # String, a leaf attribute type: should have example
          name_attr =  described[:type][:attributes][:name]
          expect(name_attr).to include(:example)
          expect(name_attr[:type]).not_to include(:example)

          # Struct, a non-leaf attribute type: shouldn't have example
          ts_attr = described[:type][:attributes][:timestamps]
          expect(ts_attr).not_to include(:example)
          expect(ts_attr[:type]).not_to include(:example)

          # DateTime inside a Struct, a nested leaf attribute type: should have example
          born_attr = ts_attr[:type][:attributes][:born_at]
          expect(born_attr).to include(:example)
          expect(born_attr[:type]).not_to include(:example)
        end
      end
    end
  end

  context 'parse' do
    let(:loaded_object) { double("I'm loaded") }
    it 'loads and validates' do
      expect(attribute).to receive(:load).with(value, Attributor::DEFAULT_ROOT_CONTEXT).and_return(loaded_object)
      expect(attribute).to receive(:validate).with(loaded_object, Attributor::DEFAULT_ROOT_CONTEXT).and_call_original

      attribute.parse(value)
    end
  end

  context 'checking options' do
    it 'raises for invalid options' do
      expect do
        Attributor::Attribute.new(Integer, unknown_opt: true)
      end.to raise_error(/unsupported option/)
    end

    it 'has a spec that we try to validate the :default value' do
      expect do
        Attributor::Attribute.new(Integer, default: 'not an okay integer')
      end.to raise_error(/Default value doesn't have the correct attribute type/)
    end

    context 'custom_data' do
      it 'raises when not a hash' do
        expect do
          Attributor::Attribute.new(Integer, custom_data: 1)
        end.to raise_error(/custom_data must be a Hash/)
      end

      it 'does not raise for hashes' do
        expect do
          Attributor::Attribute.new(Integer, custom_data: { loggable: true })
        end.not_to raise_error
      end
    end
  end

  context 'example' do
    let(:example) { nil }

    context 'with nothing specified' do
      let(:attribute_options) { {} }
      before do
        expect(type).to receive(:example).and_return(example)
      end

      it 'defers to the type' do
        expect(attribute.example).to be example
      end
    end

    context 'with an attribute that has the values option set' do
      let(:values) { %w(one two) }
      let(:attribute_options) { { values: values } }
      it 'picks a random value' do
        expect(values).to include subject.example
      end
    end

    context 'deterministic examples' do
      let(:example) { /\w+/ }
      let(:attribute_options) { { example: example } }

      it 'can take a context to pre-seed the random number generator' do
        example_1 = subject.example(['context'])
        example_2 = subject.example(['context'])

        expect(example_1).to eq example_2
      end

      it 'can take a context to pre-seed the random number generator' do
        example_1 = subject.example(['context'])
        example_2 = subject.example(['different context'])

        expect(example_1).not_to eq example_2
      end
    end

    context 'with an example option' do
      let(:example) { 'Bob' }
      let(:attribute_options) { { example: example, regexp: /Bob/ } }

      its(:example) { should eq example }

      context 'that is not valid' do
        let(:example) { 'Frank' }
        it 'raises a validation error' do
          expect do
            subject.example
          end.to raise_error(Attributor::AttributorException, /Error generating example/)
        end
      end
    end
  end

  context 'example_from_options' do
    let(:example) { nil }
    let(:generated_example) { example }
    let(:attribute_options) { { example: example } }
    let(:parent) { nil }
    let(:context) { Attributor::DEFAULT_ROOT_CONTEXT }

    subject(:example_result) { attribute.example_from_options(parent, context) }
    before do
      expect(attribute).to receive(:load).with(generated_example, an_instance_of(Array)).and_call_original
    end

    context 'with a string' do
      let(:example) { 'example' }

      it { should be example }
    end

    context 'with an integer' do
      let(:type) { Attributor::Integer }
      let(:example) { 5 }
      it { should be example }
    end

    context 'with a regexp' do
      let(:example) { /\w+/ }
      let(:generated_example) { /\w+/.gen }

      it 'calls #gen on the regexp' do
        expect(example).to receive(:gen).and_return(generated_example)

        expect(example_result).to match example
      end

      context 'for a type with a non-String native_type' do
        let(:type) { Attributor::Integer }
        let(:example) { /\d{5}/ }
        let(:generated_example) { /\d{5}/.gen }

        it 'coerces the example value properly' do
          expect(example).to receive(:gen).and_return(generated_example)
          expect(type).to receive(:load).and_call_original

          expect(example_result).to be_kind_of(type.native_type)
        end
      end
    end

    context 'with a proc' do
      let(:parent) { Object.new }

      context 'with one argument' do
        let(:example) { ->(_obj) { 'ok' } }
        let(:generated_example) { 'ok' }

        before do
          expect(example).to receive(:call).with(parent).and_return(generated_example)
        end

        it 'passes any given parent through to the example proc' do
          expect(example_result).to eq 'ok'
        end
      end

      context 'with two arguments' do
        let(:example) { ->(_obj, context) { "#{context} ok" } }
        let(:generated_example) { "#{context} ok" }
        let(:context) { ['some_context'] }
        before do
          expect(example).to receive(:call).with(parent, context).and_return(generated_example)
        end

        it 'passes any given parent through to the example proc' do
          expect(example_result).to eq "#{context} ok"
        end
      end
    end

    context 'with an Collection (of Strings)' do
      let(:type) { Attributor::Collection.of(String) }
      let(:example) { ['one'] }
      it { should eq example }
    end
  end

  context 'load' do
    let(:context) { ['context'] }
    let(:value) { '1' }

    it 'delegates to type.load' do
      expect(type).to receive(:load).with(value, context, {})
      attribute.load(value, context)
    end

    it 'passes options to type.load' do
      expect(type).to receive(:load).with(value, context, foo: 'bar')
      attribute.load(value, context, foo: 'bar')
    end

    context 'applying default values' do
      let(:value) { nil }
      let(:default_value) { 'default value' }
      let(:attribute_options) { { default: default_value } }

      subject(:result) { attribute.load(value) }

      context 'for nil' do
        it { should eq default_value }
      end

      context 'for false' do
        let(:type) { Attributor::Boolean }
        let(:default_value) { false }
        it { should eq default_value }
      end

      context 'for a Proc-based default value' do
        let(:context) { ['$'] }
        subject(:result) { attribute.load(value, context) }

        context 'with no arguments arguments' do
          let(:default_value) { proc { 'no_params' } }
          it { should eq default_value.call }
        end

        context 'with 1 argument (the parent)' do
          let(:default_value) { proc { |parent| "parent is fake: #{parent.class}" } }
          it { should eq 'parent is fake: Attributor::FakeParent' }
        end

        context 'with 2 argument (the parent and the contents)' do
          let(:default_value) { proc { |parent, context| "parent is fake: #{parent.class} and context is: #{context}" } }
          it { should eq 'parent is fake: Attributor::FakeParent and context is: ["$"]' }
        end

        context 'which attempts to use the parent (which is not supported for the moment)' do
          let(:default_value) { proc { |parent| "any parent method should spit out warning: [#{parent.something}]" } }
          it 'should output a warning' do
            begin
              old_verbose = $VERBOSE
              $VERBOSE = nil
              expect(Kernel).to receive(:warn).and_call_original
              expect(attribute.load(value, context)).to eq 'any parent method should spit out warning: []'
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
            let(:attribute_options) { { required: true } }
            context 'with a nil value' do
              let(:value) { nil }
              it 'returns an error' do
                expect(attribute.validate(value, context).first).to eq 'Attribute context is required'
              end
            end
          end

          context ':values' do
            let(:values) { %w(one two) }
            let(:attribute_options) { { values: values } }
            let(:value) { nil }

            subject(:errors) { attribute.validate(value, context) }

            context 'with a value that is allowed' do
              let(:value) { 'one' }
              it 'returns no errors' do
                expect(errors).to be_empty
              end
            end

            context 'with a value that is not allowed' do
              let(:value) { 'three' }
              it 'returns an error indicating the problem' do
                expect(errors.first).to match /is not within the allowed values/
              end
            end
          end
        end

        it 'calls the right validate_X methods?' do
          expect(attribute).to receive(:validate_type).with(value, context).and_call_original
          expect(attribute).not_to receive(:validate_dependency)
          expect(type).to receive(:validate).and_call_original
          attribute.validate(value, context)
        end
      end

      context '#validate_type' do
        subject(:errors) { attribute.validate_type(value, context) }

        context 'with a value of the right type' do
          let(:value) { 'one' }
          it 'returns no errors' do
            expect(errors).to be_empty
          end
        end

        context 'with a value of a value different than the native_type' do
          let(:value) { 1 }

          it 'returns errors' do
            expect(errors).not_to be_empty
            expect(errors.first).to match /is of the wrong type/
          end
        end
      end

      context '#validate_missing_value' do
        let(:key) { '$.instance.ssh_key.name' }
        let(:value) { /\w+/.gen }

        let(:attribute_options) { { required_if: key } }

        let(:ssh_key) { double('ssh_key', name: value) }
        let(:instance) { double('instance', ssh_key: ssh_key) }

        before { Attributor::AttributeResolver.current.register('instance', instance) }

        let(:attribute_context) { ['$', 'params', 'key_material'] }
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
          let(:value) { 'default_ssh_key_name' }
          # subject(:errors) { attribute.validate_missing_value('') }

          context 'where the target attribute exists, and matches the predicate' do
            let(:attribute_options) { { required_if: { key => /default/ } } }

            it { should_not be_empty }

            its(:first) { should match /Attribute #{Regexp.quote(Attributor.humanize_context(attribute_context))} is required when #{Regexp.quote(key)} matches/ }
          end

          context 'where the target attribute exists, but does not match the predicate' do
            let(:attribute_options) { { required_if: { key => /other/ } } }

            it { should be_empty }
          end

          context 'where the target attribute does not exist' do
            let(:attribute_options) { { required_if: { key => /default/ } } }
            let(:ssh_key) { double('ssh_key', name: nil) }

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
        expect(attribute.attributes).to eq type.attributes
      end

      # it 'has compiled_definition' do
      #  attribute.compiled_definition.should eq type.definition
      # end

      it 'merges its options with those of the compiled_definition' do
        expect(attribute.options).to eq attribute_options.merge(type_options)
      end

      it 'describe handles sub-attributes nicely' do
        describe = attribute.describe(false)

        expect(describe[:type][:name]).to eq type.name
        common_options = attribute_options.select { |k, _v| Attributor::Attribute.TOP_LEVEL_OPTIONS.include? k }
        special_options = attribute_options.reject { |k, _v| Attributor::Attribute.TOP_LEVEL_OPTIONS.include? k }
        common_options.each do |k, v|
          expect(describe[k]).to eq v
        end
        special_options.each do |k, v|
          expect(describe[:options][k]).to eq v
        end
        type_options.each do |k, v|
          expect(describe[:options][k]).to eq v
        end

        attribute.attributes.each do |name, _attr|
          expect(describe[:type][:attributes]).to have_key(name)
        end
      end

      it 'supports deterministic examples' do
        example_1 = attribute.example(['Chicken context'])
        example_2 = attribute.example(['Chicken context'])

        expect(example_1.attributes).to eq(example_2.attributes)
      end

      context '#validate' do
        let(:chicken) { Chicken.example }
        let(:type_attributes) { type.attributes }

        it 'validates sub-attributes' do
          errors = attribute.validate(chicken)
          expect(errors).to be_empty
        end

        context 'with a failing validation' do
          subject(:chicken) { Chicken.example(age: 150, email: 'foo') }
          let(:email_validation_response) { ["$.email value \(#{chicken.email}\) does not match regexp (/@/)"] }
          let(:age_validation_response) { ["$.age value \(#{chicken.age}\) is larger than the allowed max (120)"] }

          it 'collects sub-attribute validation errors' do
            errors = attribute.validate(chicken)
            expect(errors).to match_array(age_validation_response | email_validation_response)
          end
        end
      end

      context '#validate_missing_value' do
        let(:type) { Duck }
        let(:attribute_name) { nil }
        let(:attribute) { Duck.attributes[attribute_name] }

        let(:attribute_context) { ['$', 'duck', attribute_name.to_s] }
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
            its(:first) { should eq 'Attribute $.duck.email is required when name (for $.duck) is present.' }
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
            its(:first) { should match /Attribute #{Regexp.quote('$.duck.age')} is required when name #{Regexp.quote('(for $.duck)')} matches/ }
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
      let(:type) { Attributor::Collection.of(member_type) }
      let(:member_options) { { max: 10 } }
      let(:attribute_options) { { member_options: member_options } }

      context 'the member_attribute of that type' do
        subject(:member_attribute) { attribute.type.member_attribute }

        it { should be_kind_of(Attributor::Attribute) }
        its(:type) { should be(member_type) }
        its(:options) { should eq(member_options) }
      end

      context 'working with members' do
        let(:values) { ['1', 2, 12] }

        it 'loads' do
          expect(attribute.load(values)).to match_array [1, 2, 12]
        end

        it 'validates' do
          object = attribute.load(values)
          errors = attribute.validate(object)

          expect(errors).to have(1).item
          expect(errors[0]).to match /value \(12\) is larger/
        end
      end
    end

    context 'of a Model (or Struct) type' do
      subject(:attribute) { Attributor::Attribute.new(type, attribute_options, &attribute_block) }

      let(:attribute_block) { proc { attribute :angry, required: true } }
      let(:attribute_options) { { reference: Chicken, member_options: member_options } }
      let(:member_type) { Attributor::Struct }
      let(:type) { Attributor::Collection.of(member_type) }
      let(:member_options) { {} }

      context 'the member_attribute of that type' do
        subject(:member_attribute) { attribute.type.member_attribute }
        it { should be_kind_of(Attributor::Attribute) }
        its(:options) { should eq(member_options.merge(reference: Chicken, identity: :email)) }
        its(:attributes) { should have_key :angry }
        it 'inherited the type and options from the reference' do
          expect(member_attribute.attributes[:angry].type).to be(Chicken.attributes[:angry].type)
          expect(member_attribute.attributes[:angry].options).to eq(Chicken.attributes[:angry].options.merge(required: true))
        end
      end
    end
  end
end
