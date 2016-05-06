require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Hash do
  subject(:type) { Attributor::Hash }

  its(:native_type) { should be(type) }
  its(:key_type) { should be(Attributor::Object) }
  its(:value_type) { should be(Attributor::Object) }
  its(:dsl_class) { should be(Attributor::HashDSLCompiler) }

  context 'attributes' do
    context 'with an exception from the definition block' do
      subject(:broken_model) do
        Class.new(Attributor::Model) do
          attributes do
            raise 'sorry :('
            attribute :name, String
          end
        end
      end

      it 'throws original exception upon first run' do
        lambda do
          broken_model.attributes
        end.should raise_error(RuntimeError, 'sorry :(')
      end

      it 'throws InvalidDefinition for subsequent access' do
        begin
          broken_model.attributes
        rescue
          nil
        end

        lambda do
          broken_model.attributes
        end.should raise_error(Attributor::InvalidDefinition)
      end

      it 'throws for any attempts at using of an instance of it' do
        begin
          broken_model.attributes
        rescue
          nil
        end

        instance = broken_model.new
        lambda do
          instance.name
        end.should raise_error(Attributor::InvalidDefinition)
      end
    end
  end

  context 'default options' do
    subject(:options) { type.options }
    it 'has allow_extra false' do
      options[:allow_extra].should be(false)
    end
  end

  context '.example' do
    context 'for a simple hash' do
      subject(:example) { Attributor::Hash.example }

      it { should be_kind_of(Attributor::Hash) }
      it { should be_empty }
      it { should eq(::Hash.new) }
    end

    context 'for a typed hash' do
      subject(:example) { Attributor::Hash.of(value: Integer).example }

      it 'returns a hash with keys and/or values of the right type' do
        example.should be_kind_of(Attributor::Hash)
        example.keys.size.should > 0
        example.values.all? { |v| v.is_a? Integer }.should be(true)
      end
    end

    context 'for a Hash with defined keys' do
      let(:name) { 'bob' }
      let(:something) { 'else' }

      subject(:example) { HashWithStrings.example(name: name, something: something) }

      context 'resolves a lazy attributes on demand' do
        before { example.lazy_attributes.keys.should eq [:name, :something] }
        after { example.lazy_attributes.keys.should eq [:something] }

        it 'using get' do
          example.get(:name).should be name
        end
        it 'using []' do
          example[:name].should be name
        end

        it 'using set' do
          example.set :name, 'not bob'
          example.get(:name).should == 'not bob'
        end
        it 'using []=' do
          example[:name] = 'not bob'
          example[:name].should == 'not bob'
        end
      end

      its(:size) { should eq 2 }
      its(:values) { should =~ [name, something] }
      its(:keys) { should =~ [:name, :something] }
      it do
        should_not be_empty
      end

      it 'responds to key? correctly' do
        example.key?(:name).should be(true)
        example.key?(:something).should be(true)
      end

      it 'enumerates the contents' do
        example.collect { |k, _v| k }.should eq [:name, :something]
      end

      it 'enumerates the contents using each_pair' do
        pairs = []
        example.each_pair { |pair| pairs << pair }
        pairs.should =~ [[:name, name], [:something, something]]
      end

      its(:contents) { should eq ({ name: name, something: something }) }
      it 'does not create methods for the keys' do
        example.should_not respond_to(:name)
        example.should_not respond_to(:something)
      end
    end

    context 'using a non array context' do
      it 'should work for hashes with key/value types' do
        expect { Attributor::Hash.of(key: String, value: String).example('Not an Array') }.to_not raise_error
      end
      it 'should work for hashes with keys defined' do
        block = proc { key 'a string', String }
        hash = Attributor::Hash.of(key: String).construct(block)

        expect { hash.example('Not an Array') }.to_not raise_error
      end
    end
  end

  context '.load' do
    let(:value) { { one: 'two', three: 4 } }
    subject(:hash) { type.load(value) }

    context 'for nil with recurse: true' do
      let(:value) { nil }
      subject(:hash) { HashWithModel.load(value, recurse: true) }

      it 'works' do
        hash[:name].should eq('Turkey McDucken')
        hash[:chicken].age.should eq(1)
      end
    end

    context 'for a simple hash' do
      it { should eq(value) }
      it 'equals the hash' do
        hash.should eq value
        hash[:one].should eq('two')
        hash[:three].should eq(4)
      end
    end

    context 'for a JSON encoded hash' do
      let(:value_as_hash) { { 'one' => 'two', 'three' => 4 } }
      let(:value) { JSON.dump(value_as_hash) }
      it 'deserializes and converts it to a real hash' do
        hash.should eq(value_as_hash)
        hash['one'].should eq 'two'
      end
    end

    context 'for a typed hash' do
      subject(:type) { Attributor::Hash.of(key: String, value: Integer) }
      context 'with good values' do
        let(:value) { { one: '1', 'three' => 3 } }
        it 'coerces good values into the correct types' do
          hash.should eq('one' => 1, 'three' => 3)
          hash['one'].should eq(1)
        end
      end

      context 'with incompatible values' do
        let(:value) { { one: 'two', three: 4 } }
        it 'fails' do
          expect do
            type.load(value)
          end.to raise_error(/invalid value for Integer/)
        end
      end
    end

    context 'for a partially typed hash' do
      subject(:type) { Attributor::Hash.of(value: Integer) }
      context 'with good values' do
        let(:value) { { one: '1', [1, 2, 3] => 3 } }
        it 'coerces only values into the correct types (and leave keys alone)' do
          hash.should eq(:one => 1, [1, 2, 3] => 3)
        end
      end
    end

    context 'for another Attributor Hash with a compatible type definition' do
      let(:other_hash) do
        Attributor::Hash.of(key: Integer, value: Integer)
      end
      let(:value) { other_hash.example }
      it 'succeeds' do
        type.load(value)
      end
    end

    context 'for Hash with defined keys' do
      let(:type) do
        Class.new(Attributor::Hash) do
          keys do
            key 'id', Integer
            key 'name', String, default: 'unnamed'
            key 'chicken', Chicken
          end
        end
      end

      let(:value) { { 'chicken' => Chicken.example } }

      subject(:hash) { type.load(value) }

      it { should_not have_key('id') }
      it 'has the defaulted key' do
        hash.should have_key('name')
        hash['name'].should eq('unnamed')
      end
    end

    context 'for a different Attributor Hash' do
      let(:loader_hash) do
        Class.new(Attributor::Hash) do
          keys do
            key :id, String
            key :name, String
          end
        end
      end
      let(:value) { value_hash.example }
      context 'with compatible key definitions' do
        let(:value_hash) do
          Class.new(Attributor::Hash) do
            keys do
              key :id, String
            end
          end
        end

        it 'succeeds' do
          loader_hash.load(value)
        end

        context 'with a not compatible key definition' do
          let(:value_hash) do
            Class.new(Attributor::Hash) do
              keys do
                key :id, String
                key :weird_key, String
              end
            end
          end

          it 'complains about an unknown key' do
            expect do
              loader_hash.load(value)
            end.to raise_error(Attributor::AttributorException, /Unknown key received: :weird_key/)
          end
        end
      end
    end
  end

  context '.of' do
    context 'specific key and value types' do
      let(:key_type) { String }
      let(:value_type) { Integer }

      subject(:type) { Attributor::Hash.of(key: key_type, value: value_type) }

      it { should be_a(::Class) }
      its(:ancestors) { should include(Attributor::Hash) }
      its(:key_type) { should == Attributor::String }
      its(:value_type) { should == Attributor::Integer }

      context '.load' do
        let(:value) { { one: '2', 3 => 4 } }

        subject(:hash) { type.load(value) }

        it 'coerces the types properly' do
          hash['one'].should eq(2)
          hash['3'].should eq(4)
        end
      end
    end
  end

  context '.construct' do
    let(:block) do
      proc do
        key 'a string', String
        key '1', Integer
        key :some_date, DateTime
        key 'defaulted', String, default: 'default value'
      end
    end

    subject(:type) { Attributor::Hash.construct(block) }

    it do
      should_not be(Attributor::Hash)
    end

    context 'loading' do
      let(:date) { DateTime.parse('2014-07-15') }
      let(:value) do
        { 'a string' => 12, '1' => '2', :some_date => date.to_s }
      end

      subject(:hash) { type.load(value) }

      it 'loads' do
        hash['a string'].should eq('12')
        hash['1'].should eq(2)
        hash[:some_date].should eq(date)
        hash['defaulted'].should eq('default value')
      end

      context 'with unknown keys in input' do
        it 'raises an error' do
          expect do
            type.load('other_key' => :value)
          end.to raise_error(Attributor::AttributorException)
        end
      end

      context 'with a key_type' do
        let(:block) do
          proc do
            key 'a string', String
            key '1', Integer
            key 'some_date', DateTime
            key 'defaulted', String, default: 'default value'
          end
        end

        subject(:type) { Attributor::Hash.of(key: String).construct(block) }
        let(:value) do
          { 'a string' => 12, 1 => '2', :some_date => date.to_s }
        end

        it 'loads' do
          hash['a string'].should eq('12')
          hash['1'].should eq(2)
          hash['some_date'].should eq(date)
          hash['defaulted'].should eq('default value')
        end
      end
    end

    context 'with key names of the wrong type' do
      let(:block) do
        proc do
          key :some_date, DateTime
        end
      end

      it 'raises an error' do
        expect do
          Attributor::Hash.of(key: String).construct(block).keys
        end.to raise_error(/Invalid key: :some_date, must be instance of String/)
      end
    end
  end

  context '.check_option!' do
    context ':case_insensitive_load' do
      it 'is valid when key_type is a string' do
        Attributor::Hash.of(key: String).check_option!(:case_insensitive_load, true).should == :ok
      end

      it 'is invalid when key_type is non-string' do
        expect do
          Attributor::Hash.of(key: Integer).check_option!(:case_insensitive_load, true)
        end.to raise_error(Attributor::AttributorException, /:case_insensitive_load may not be used/)
      end
    end
    it 'rejects unknown options' do
      subject.check_option!(:bad_option, Object).should == :unknown
    end
  end

  context '.add_requirement' do
    let(:req_type) { :all }
    let(:req) { double('requirement', type: req_type, attr_names: req_attributes) }
    context 'with valid attributes' do
      let(:req_attributes) { [:name] }
      it 'successfully saves it in the class' do
        HashWithStrings.add_requirement(req)
        HashWithStrings.requirements.should include(req)
      end
    end
    context 'with attributes not defined in the class' do
      let(:req_attributes) { [:name, :invalid, :notgood] }
      it 'it complains loudly' do
        expect do
          HashWithStrings.add_requirement(req)
        end.to raise_error('Invalid attribute name(s) found (invalid, notgood) when defining a requirement of type all for HashWithStrings .The only existing attributes are [:name, :something]')
      end
    end
  end

  context '.dump' do
    let(:value) { { one: 1, two: 2 } }
    let(:opts) { {} }

    it 'it is Dumpable' do
      type.new.is_a?(Attributor::Dumpable).should be(true)
    end

    context 'for a simple (untyped) hash' do
      it 'returns the untouched hash value' do
        type.dump(value, opts).should eq(value)
      end
    end

    context 'for a typed hash' do
      before do
        subtype.should_receive(:dump).exactly(2).times.and_call_original
      end
      let(:value1) { { first: 'Joe', last: 'Moe' } }
      let(:value2) { { first: 'Mary', last: 'Foe' } }
      let(:value) { { id1: subtype.new(value1), id2: subtype.new(value2) } }
      let(:subtype) do
        Class.new(Attributor::Model) do
          attributes do
            attribute :first, String
            attribute :last, String
          end
        end
      end
      let(:type) { Attributor::Hash.of(key: String, value: subtype) }

      it 'returns a hash with the dumped values and keys' do
        dumped_value = type.dump(value, opts)
        dumped_value.should be_kind_of(::Hash)
        dumped_value.keys.should =~ %w(id1 id2)
        dumped_value.values.should have(2).items
        dumped_value['id1'].should == value1
        dumped_value['id2'].should == value2
      end

      context 'that has nil attribute values' do
        let(:value) { { id1: nil, id2: subtype.new(value2) } }

        it 'correctly returns nil rather than trying to dump their contents' do
          dumped_value = type.dump(value, opts)
          dumped_value.should be_kind_of(::Hash)
          dumped_value.keys.should =~ %w(id1 id2)
          dumped_value['id1'].should.nil?
          dumped_value['id2'].should == value2
        end
      end
    end
  end

  context '#validate' do
    context 'for a key and value typed hash' do
      let(:key_type) { Integer }
      let(:value_type) { DateTime }

      let(:type) { Attributor::Hash.of(key: key_type, value: value_type) }
      subject(:hash) { type.new('one' => :two) }

      it 'returns errors for key and value' do
        errors = hash.validate
        errors.should have(2).items

        errors.should include('Attribute $.key("one") received value: "one" is of the wrong type (got: String, expected: Attributor::Integer)')
        errors.should include('Attribute $.value(:two) received value: :two is of the wrong type (got: Symbol, expected: Attributor::DateTime)')
      end
    end

    context 'for a hash with defined keys' do
      let(:block) do
        proc do
          key 'integer', Integer
          key 'datetime', DateTime
          key 'not-optional', String, required: true
        end
      end

      let(:type) { Attributor::Hash.construct(block) }

      let(:values) { { 'integer' => 'one', 'datetime' => 'now' } }
      subject(:hash) { type.new(values) }

      it 'validates the keys' do
        errors = hash.validate
        errors.should have(3).items
        errors.should include('Attribute $.key("not-optional") is required')
      end
    end

    context 'with requirements defined' do
      let(:type) { Attributor::Hash.construct(block) }

      context 'using requires' do
        let(:block) do
          proc do
            key 'name', String
            key 'consistency', Attributor::Boolean
            key 'availability', Attributor::Boolean
            key 'partitioning', Attributor::Boolean
            requires 'consistency', 'availability'
            requires.all 'name' # Just to show that it is equivalent to 'requires'
          end
        end

        it 'complains not all the listed elements are set (false or true)' do
          errors = type.new('name' => 'CAP').validate
          errors.should have(2).items
          %w(consistency availability).each do |name|
            errors.should include("Key #{name} is required for $.")
          end
        end
      end

      context 'using at_least(n)' do
        let(:block) do
          proc do
            key 'name', String
            key 'consistency', Attributor::Boolean
            key 'availability', Attributor::Boolean
            key 'partitioning', Attributor::Boolean
            requires.at_least(2).of 'consistency', 'availability', 'partitioning'
          end
        end

        it 'complains if less than 2 in the group are set (false or true)' do
          errors = type.new('name' => 'CAP', 'consistency' => false).validate
          errors.should have(1).items
          errors.should include(
            'At least 2 keys out of ["consistency", "availability", "partitioning"] are required to be passed in for $. Found ["consistency"]'
          )
        end
      end

      context 'using at_most(n)' do
        let(:block) do
          proc do
            key 'name', String
            key 'consistency', Attributor::Boolean
            key 'availability', Attributor::Boolean
            key 'partitioning', Attributor::Boolean
            requires.at_most(2).of 'consistency', 'availability', 'partitioning'
          end
        end

        it 'complains if more than 2 in the group are set (false or true)' do
          errors = type.new('name' => 'CAP', 'consistency' => false, 'availability' => true, 'partitioning' => false).validate
          errors.should have(1).items
          errors.should include('At most 2 keys out of ["consistency", "availability", "partitioning"] can be passed in for $. Found ["consistency", "availability", "partitioning"]')
        end
      end

      context 'using exactly(n)' do
        let(:block) do
          proc do
            key 'name', String
            key 'consistency', Attributor::Boolean
            key 'availability', Attributor::Boolean
            key 'partitioning', Attributor::Boolean
            requires.exactly(1).of 'consistency', 'availability', 'partitioning'
          end
        end

        it 'complains if less than 1 in the group are set (false or true)' do
          errors = type.new('name' => 'CAP').validate
          errors.should have(1).items
          errors.should include('Exactly 1 of the following keys ["consistency", "availability", "partitioning"] are required for $. Found 0 instead: []')
        end
        it 'complains if more than 1 in the group are set (false or true)' do
          errors = type.new('name' => 'CAP', 'consistency' => false, 'availability' => true).validate
          errors.should have(1).items
          errors.should include('Exactly 1 of the following keys ["consistency", "availability", "partitioning"] are required for $. Found 2 instead: ["consistency", "availability"]')
        end
      end

      context 'using exclusive' do
        let(:block) do
          proc do
            key 'name', String
            key 'consistency', Attributor::Boolean
            key 'availability', Attributor::Boolean
            key 'partitioning', Attributor::Boolean
            requires.exclusive 'consistency', 'availability', 'partitioning'
          end
        end

        it 'complains if two or more in the group are set (false or true)' do
          errors = type.new('name' => 'CAP', 'consistency' => false, 'availability' => true).validate
          errors.should have(1).items
          errors.should include('keys ["consistency", "availability"] are mutually exclusive for $.')
        end
      end

      context 'through a block' do
        let(:block) do
          proc do
            key 'name', String
            key 'consistency', Attributor::Boolean
            key 'availability', Attributor::Boolean
            key 'partitioning', Attributor::Boolean
            requires do
              all 'name'
              all.of 'name' # Equivalent to .all
              at_least(1).of 'consistency', 'availability', 'partitioning'
            end
            # Silly example, just to show that block and inline requires can be combined
            requires.at_most(3).of 'consistency', 'availability', 'partitioning'
          end
        end

        it 'complains not all the listed elements are set (false or true)' do
          errors = type.new('name' => 'CAP').validate
          errors.should have(1).items
          errors.should include(
            'At least 1 keys out of ["consistency", "availability", "partitioning"] are required to be passed in for $. Found none'
          )
        end
      end
    end
  end

  context 'in an Attribute' do
    let(:options) { {} }
    subject(:attribute) { Attributor::Attribute.new(Attributor::Hash, options) }

    context 'with an example option that is a proc' do
      let(:example_hash) { { key: 'value' } }
      let(:options) { { example: proc { example_hash } } }
      it 'uses the hash' do
        attribute.example.should eq(example_hash)
      end
    end
  end

  context '.describe' do
    let(:example) { nil }
    subject(:description) { type.describe(example: example) }
    context 'for hashes with key and value types' do
      it 'describes the type correctly' do
        description[:name].should eq('Hash')
        description[:key].should eq(type: { name: 'Object', id: 'Attributor-Object', family: 'any' })
        description[:value].should eq(type: { name: 'Object', id: 'Attributor-Object', family: 'any' })
      end
    end

    context 'for hashes specific keys defined' do
      let(:block) do
        proc do
          key 'a string', String
          key '1', Integer, min: 1, max: 20
          key 'some_date', DateTime
          key 'defaulted', String, default: 'default value'
          requires do
            all.of '1', 'some_date'
            exclusive 'some_date', 'defaulted'
            at_least(1).of 'a string', 'some_date'
            at_most(2).of 'a string', 'some_date'
            exactly(1).of 'a string', 'some_date'
          end
        end
      end

      let(:type) { Attributor::Hash.of(key: String).construct(block) }

      it 'describes the type correctly' do
        description[:name].should eq('Hash')
        description[:key].should eq(type: { name: 'String', id: 'Attributor-String', family: 'string' })
        description.should_not have_key(:value)
      end

      it 'describes the type attributes correctly' do
        attrs = description[:attributes]

        attrs['a string'].should eq(type: { name: 'String', id: 'Attributor-String', family: 'string' })
        attrs['1'].should eq(type: { name: 'Integer', id: 'Attributor-Integer', family: 'numeric' }, options: { min: 1, max: 20 })
        attrs['some_date'].should eq(type: { name: 'DateTime', id: 'Attributor-DateTime', family: 'temporal' })
        attrs['defaulted'].should eq(type: { name: 'String', id: 'Attributor-String', family: 'string' }, default: 'default value')
      end

      it 'describes the type requirements correctly' do
        reqs = description[:requirements]
        reqs.should be_kind_of(Array)
        reqs.size.should be(5)
        reqs.should include(type: :all, attributes: %w(1 some_date))
        reqs.should include(type: :exclusive, attributes: %w(some_date defaulted))
        reqs.should include(type: :at_least, attributes: ['a string', 'some_date'], count: 1)
        reqs.should include(type: :at_most, attributes: ['a string', 'some_date'], count: 2)
        reqs.should include(type: :exactly, attributes: ['a string', 'some_date'], count: 1)
      end

      context 'merging requires.all with attribute required: true' do
        let(:block) do
          proc do
            key 'required string', String, required: true
            key '1', Integer
            key 'some_date', DateTime
            requires do
              all.of 'some_date'
            end
          end
        end
        it 'includes attributes with required: true into the :all requirements' do
          req_all = description[:requirements].select { |r| r[:type] == :all }.first
          req_all[:attributes].should include('required string', 'some_date')
        end
      end

      context 'creates the :all requirement when any attribute has required: true' do
        let(:block) do
          proc do
            key 'required string', String, required: true
            key 'required integer', Integer, required: true
          end
        end
        it 'includes attributes with required: true into the :all requirements' do
          req_all = description[:requirements].select { |r| r[:type] == :all }.first
          req_all.should_not be(nil)
          req_all[:attributes].should include('required string', 'required integer')
        end
      end

      context 'with an example' do
        let(:example) { type.example }

        it 'should have the matching example for each leaf key' do
          description[:attributes].keys.should =~ type.keys.keys
          description[:attributes].each do |name, sub_description|
            sub_description.should have_key(:example)
            val = type.attributes[name].dump(example[name])
            sub_description[:example].should eq val
          end
        end
      end
    end
  end

  context '#dump' do
    let(:key_type) { String }
    let(:value_type) { Integer }
    let(:hash) { { one: '2', 3 => 4 } }
    let(:type) { Attributor::Hash.of(key: key_type, value: value_type) }
    let(:value) { type.load(hash) }

    subject(:output) { value.dump }

    it 'dumps the contents properly' do
      output.should be_kind_of(::Hash)
      output.should eq('one' => 2, '3' => 4)
    end

    context 'with a model as value type' do
      let(:value_type) do
        Class.new(Attributor::Model) do
          attributes do
            attribute :first, String
            attribute :last, String
          end
        end
      end
      let(:hash) { { one: value_type.example } }
    end
    context 'will always return a top level hash' do
      subject(:type_dump) { type.dump(value) }
      let(:key_type) { Attributor::Object }
      let(:value_type) { Attributor::Object }

      it 'even when key/types are object' do
        subject.should be_kind_of(::Hash)
        subject.should eq(hash)
      end
    end

    context 'for a hash with defined keys' do
      let(:type) do
        Class.new(Attributor::Hash) do
          keys do
            key 'id', Integer
            key 'chicken', Chicken
          end
        end
      end

      let(:chicken) { { 'name' => 'bob' } }

      let(:value) { { 'id' => '1', 'chicken' => chicken } }
      let(:expected) { { 'id' => 1, 'chicken' => Chicken.dump(chicken) } }

      it 'properly dumps the values' do
        type.dump(value).should eq(expected)
      end

      context 'with allow_extra: true' do
        let(:type) do
          Class.new(Attributor::Hash) do
            keys allow_extra: true do
              key 'id', Integer
              key 'chicken', Chicken
            end
          end
        end

        let(:value) { { 'id' => '1', 'chicken' => chicken, 'rank' => 'bob rank' } }
        let(:expected) { { 'id' => 1, 'chicken' => Chicken.dump(chicken), 'rank' => 'bob rank' } }
        it 'preserves the extra keys at the top level' do
          type.dump(value).should eq(expected)
        end

        context 'with extra option' do
          let(:type) do
            Class.new(Attributor::Hash) do
              keys allow_extra: true do
                key 'id', Integer
                key 'chicken', Chicken
                extra 'other', Attributor::Hash
              end
            end
          end

          let(:expected) { { 'id' => 1, 'chicken' => Chicken.dump(chicken), 'other' => { 'rank' => 'bob rank' } } }
          it 'dumps the extra keys inside the subhash' do
            type.dump(value).should eq(expected)
          end
        end
      end
    end
  end

  context '.from_hash' do
    context 'without allowing extra keys' do
      let(:type) do
        Class.new(Attributor::Hash) do
          self.value_type = String

          keys do
            key :one, String
            key :two, String, default: 'two'
          end
        end
      end
      subject(:input) { {} }
      subject(:output) { type.load(input) }

      its(:class) { should be(type) }

      let(:load_context) { '$.some_root' }
      it 'complains about the extra, with the right context' do
        expect do
          type.load({ one: 'one', three: 3 }, load_context)
        end.to raise_error(Attributor::AttributorException, /Unknown key received: :three while loading \$\.some_root.key\(:three\)/)
      end
      context 'properly sets them (and loads them) in the created instance' do
        let(:input) { { one: 'one', two: 2 } }

        its(:keys) { should eq([:one, :two]) }
        its([:one]) { should eq('one') }
        its([:two]) { should eq('2') } # loaded as a string
      end
      context 'properly sets the default values when not passed in' do
        let(:input) { { one: 'one' } }

        its([:one]) { should eq('one') }
        its([:two]) { should eq('two') }
      end
    end

    context ' allowing extra keys' do
      context 'at the top level' do
        let(:type) do
          Class.new(Attributor::Hash) do
            keys allow_extra: true do
              key :one, String
            end
          end
        end
        let(:input) { { one: 'one', three: 'tres' } }
        subject(:output) { type.load(input) }

        its(:keys) { should eq([:one, :three]) }
      end
      context 'inside an :other subkey' do
        let(:type) do
          Class.new(Attributor::Hash) do
            keys allow_extra: true do
              key :one, String
              extra :other
            end
          end
        end
        let(:input) { { one: 'one', three: 'tres' } }
        subject(:output) { type.load(input) }

        its(:keys) { should =~ [:one, :other] }
        it 'has the key inside the :other hash' do
          expect(output[:other]).to eq(three: 'tres')
        end
      end
    end
  end

  context 'case_insensitive_load option' do
    let(:case_insensitive) { true }
    let(:type) { Attributor::Hash.of(key: String).construct(block, case_insensitive_load: case_insensitive) }
    let(:block) do
      proc do
        key 'downcase', Integer
        key 'UPCASE', Integer
        key 'CamelCase', Integer
      end
    end
    let(:input) { { 'DOWNCASE' => 1, 'upcase' => 2, 'CamelCase' => 3 } }
    subject(:output) { type.load(input) }

    context 'when defined' do
      it 'maps the incoming keys to defined keys, regardless of case' do
        output['downcase'].should eq(1)
        output['UPCASE'].should eq(2)
        output['CamelCase'].should eq(3)
      end
      it 'has loaded the (internal) insensitive_map upon building the definition' do
        type.definition
        type.insensitive_map.should be_kind_of(::Hash)
        type.insensitive_map.keys.should =~ %w(downcase upcase camelcase)
      end
    end

    context 'when not defined' do
      let(:case_insensitive) { false }

      it 'skips the loading of the (internal) insensitive_map' do
        type.definition
        type.insensitive_map.should be_nil
      end
    end
  end

  context 'with allow_extra keys option' do
    let(:type) do
      Class.new(Attributor::Hash) do
        self.value_type = String

        keys allow_extra: true do
          key :one, String
          key :two, String, default: 'two'
        end
      end
    end

    let(:input) { { one: 'one', three: 3 } }
    subject(:output) { type.load(input) }

    context 'that should be saved at the top level' do
      its(:keys) { should =~ [:one, :two, :three] }

      it 'loads the extra keys' do
        output[:one].should eq('one')
        output[:two].should eq('two')
        output[:three].should eq('3')
      end

      its(:validate) { should be_empty }
    end

    context 'that should be grouped into a sub-hash' do
      before do
        type.keys do
          extra :options, Attributor::Hash.of(value: Integer)
        end
      end

      its(:keys) { should =~ [:one, :two, :options] }
      it 'loads the extra keys into :options sub-hash' do
        output[:one].should eq('one')
        output[:two].should eq('two')
        output[:options].should eq(three: 3)
      end
      its(:validate) { should be_empty }

      context 'with an options value already provided' do
        its(:keys) { should =~ [:one, :two, :options] }
        let(:input) { { one: 'one', three: 3, options: { four: 4 } } }

        it 'loads the extra keys into :options sub-hash' do
          output[:one].should eq('one')
          output[:two].should eq('two')
          output[:options].should eq(three: 3, four: 4)
        end
        its(:validate) { should be_empty }
      end
    end

    context '#get and #set' do
      let(:type) do
        Class.new(Attributor::Hash) do
          keys do
            key 'id', Integer
            key 'chicken', Chicken
            extra 'others', Attributor::Hash, default: {}
          end
        end
      end

      let(:chicken) { { name: 'bob' } }
      subject(:hash) { type.new }

      context '#set' do
        it 'sets values into "extra" keys if appplicable' do
          hash.should_not have_key('others')
          hash.set 'foo', 'bar'
          hash['others'].should have_key('foo')
          hash.should have_key('others')
          hash['others']['foo'].should eq('bar')
        end

        it 'loads values before saving into the contents' do
          hash.set 'chicken', chicken
          hash['chicken'].should be_a(Chicken)
        end
      end

      context '#get' do
        before do
          hash['chicken'] = chicken
          hash['chicken'].should eq(chicken)
        end

        it 'loads and updates the saved value' do
          hash.get('chicken').should be_a(Chicken)
          hash['chicken'].should be_a(Chicken)
        end

        it 'retrieves values from an "extra" key' do
          bar = double('bar')
          hash.set 'foo', bar
          hash.get('others').get('foo').should be(bar)

          hash.get('foo').should be(bar)
        end

        it 'does not set a key that is unset' do
          hash.should_not have_key('id')
          hash.get('id').should be(nil)
          hash.should_not have_key('id')
        end
      end
    end
  end

  context '#merge' do
    let(:hash_of_strings) { Attributor::Hash.of(key: String) }
    let(:hash_of_symbols) { Attributor::Hash.of(key: Symbol) }

    let(:merger) { hash_of_strings.load('a' => 1) }
    let(:good_mergee) { hash_of_strings.load('b' => 2) }
    let(:bad_mergee) { hash_of_symbols.load(c: 3) }
    let(:result) { hash_of_strings.load('a' => 1, 'b' => 2) }

    it 'validates that the mergee is of like type' do
      expect { merger.merge(bad_mergee) }.to raise_error(ArgumentError)
      expect { merger.merge({}) }.to raise_error(TypeError)
      expect { merger.merge(nil) }.to raise_error(TypeError)
    end

    it 'returns a like-typed result' do
      expect(merger.merge(good_mergee)).to be_a(hash_of_strings)
    end

    it 'merges' do
      expect(merger.merge(good_mergee)).to eq(result)
    end
  end
end
