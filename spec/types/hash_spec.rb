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
          end
        end
      end

      it 'throws original exception upon first run' do
        expect do
          broken_model.attributes
        end.to raise_error(RuntimeError, 'sorry :(')
      end
      context 'subsequent use' do
        before do
          expect do
            broken_model.attributes
          end.to raise_error(RuntimeError, 'sorry :(')
        end

        it 'throws InvalidDefinition for subsequent access' do
          expect do
            broken_model.attributes
          end.to raise_error(Attributor::InvalidDefinition)
        end

        it 'throws for any attempts at using of an instance of it' do
          instance = broken_model.new
          expect do
            instance.name
          end.to raise_error(Attributor::InvalidDefinition)
        end

        context 'for a type with a name' do
          subject(:broken_model) do
            Class.new(Attributor::Model) do
              def self.name
                'BrokenModel'
              end
              attributes do
                raise 'sorry :('
              end
            end
          end
          it 'includes the correct type.name if applicable' do
            expect do
              broken_model.attributes
            end.to raise_error(Attributor::InvalidDefinition, /BrokenModel/)
          end
        end
      end
    end
  end

  context 'default options' do
    subject(:options) { type.options }
    it 'has allow_extra false' do
      expect(options[:allow_extra]).to be(false)
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
        expect(example).to be_kind_of(Attributor::Hash)
        expect(example.keys.size).to be > 0
        expect(example.values.all? { |v| v.is_a? Integer }).to be(true)
      end
    end

    context 'for a Hash with defined keys' do
      let(:name) { 'bob' }
      let(:something) { 'else' }

      subject(:example) { HashWithStrings.example(name: name, something: something) }

      context 'resolves a lazy attributes on demand' do
        before { expect(example.lazy_attributes.keys).to eq [:name, :something] }
        after { expect(example.lazy_attributes.keys).to eq [:something] }

        it 'using get' do
          expect(example.get(:name)).to be name
        end
        it 'using []' do
          expect(example[:name]).to be name
        end

        it 'using set' do
          example.set :name, 'not bob'
          expect(example.get(:name)).to eq 'not bob'
        end
        it 'using []=' do
          example[:name] = 'not bob'
          expect(example[:name]).to eq 'not bob'
        end
      end

      its(:size) { should eq 2 }
      its(:values) { should match_array [name, something] }
      its(:keys) { should match_array [:name, :something] }
      it do
        should_not be_empty
      end

      it 'responds to key? correctly' do
        expect(example.key?(:name)).to be(true)
        expect(example.key?(:something)).to be(true)
      end

      it 'enumerates the contents' do
        expect(example.collect { |k, _v| k }).to eq [:name, :something]
      end

      it 'enumerates the contents using each_pair' do
        pairs = []
        example.each_pair { |pair| pairs << pair }
        expect(pairs).to match_array [[:name, name], [:something, something]]
      end

      its(:contents) { should eq(name: name, something: something) }
      it 'does not create methods for the keys' do
        expect(example).not_to respond_to(:name)
        expect(example).not_to respond_to(:something)
      end
    end

    context 'using a non array context' do
      it 'should work for hashes with key/value types' do
        expect do
          Attributor::Hash.of(key: String, value: String)
                          .example('Not an Array')
        end.to_not raise_error
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
        expect(hash[:name]).to eq('Turkey McDucken')
        expect(hash[:chicken].age).to eq(1)
      end
    end

    context 'for a simple hash' do
      it { should eq(value) }
      it 'equals the hash' do
        expect(hash).to eq value
        expect(hash[:one]).to eq('two')
        expect(hash[:three]).to eq(4)
      end
    end

    context 'for a JSON encoded hash' do
      let(:value_as_hash) { { 'one' => 'two', 'three' => 4 } }
      let(:value) { JSON.dump(value_as_hash) }
      it 'deserializes and converts it to a real hash' do
        expect(hash).to eq(value_as_hash)
        expect(hash['one']).to eq 'two'
      end
    end

    context 'for a typed hash' do
      subject(:type) { Attributor::Hash.of(key: String, value: Integer) }
      context 'with good values' do
        let(:value) { { one: '1', 'three' => 3 } }
        it 'coerces good values into the correct types' do
          expect(hash).to eq('one' => 1, 'three' => 3)
          expect(hash['one']).to eq(1)
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
          expect(hash).to eq(:one => 1, [1, 2, 3] => 3)
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
        expect(hash).to have_key('name')
        expect(hash['name']).to eq('unnamed')
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
            end.to raise_error(Attributor::AttributorException,
                               /Unknown key received: :weird_key/)
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
      its(:key_type) { should eq Attributor::String }
      its(:value_type) { should eq Attributor::Integer }

      context '.load' do
        let(:value) { { one: '2', 3 => 4 } }

        subject(:hash) { type.load(value) }

        it 'coerces the types properly' do
          expect(hash['one']).to eq(2)
          expect(hash['3']).to eq(4)
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
        expect(hash['a string']).to eq('12')
        expect(hash['1']).to eq(2)
        expect(hash[:some_date]).to eq(date)
        expect(hash['defaulted']).to eq('default value')
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
          expect(hash['a string']).to eq('12')
          expect(hash['1']).to eq(2)
          expect(hash['some_date']).to eq(date)
          expect(hash['defaulted']).to eq('default value')
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
        expect(Attributor::Hash.of(key: String).check_option!(:case_insensitive_load, true)).to eq :ok
      end

      it 'is invalid when key_type is non-string' do
        expect do
          Attributor::Hash.of(key: Integer).check_option!(:case_insensitive_load, true)
        end.to raise_error(Attributor::AttributorException,
                           /:case_insensitive_load may not be used/)
      end
    end
    it 'rejects unknown options' do
      expect(subject.check_option!(:bad_option, Object)).to eq :unknown
    end
  end

  context '.add_requirement' do
    let(:req_type) { :all }
    let(:req) { double('requirement', type: req_type, attr_names: req_attributes) }
    context 'with valid attributes' do
      let(:req_attributes) { [:name] }
      it 'successfully saves it in the class' do
        HashWithStrings.add_requirement(req)
        expect(HashWithStrings.requirements).to include(req)
      end
    end
    context 'with attributes not defined in the class' do
      let(:req_attributes) { [:name, :invalid, :notgood] }
      it 'it complains loudly' do
        expect do
          HashWithStrings.add_requirement(req)
        end.to raise_error(
          'Invalid attribute name(s) found (invalid, notgood) when defining a requirement of type all for HashWithStrings .The only existing attributes are [:name, :something]'
        )
      end
    end
  end

  context '.dump' do
    let(:value) { { one: 1, two: 2 } }
    let(:opts) { {} }

    it 'it is Dumpable' do
      expect(type.new.is_a?(Attributor::Dumpable)).to be(true)
    end

    context 'for a simple (untyped) hash' do
      it 'returns the untouched hash value' do
        expect(type.dump(value, opts)).to eq(value)
      end
    end

    context 'for a typed hash' do
      before do
        expect(subtype).to receive(:dump).exactly(2).times.and_call_original
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
        expect(dumped_value).to be_kind_of(::Hash)
        expect(dumped_value.keys).to match_array %w(id1 id2)
        expect(dumped_value.values).to have(2).items
        expect(dumped_value['id1']).to eq value1
        expect(dumped_value['id2']).to eq value2
      end

      context 'that has nil attribute values' do
        let(:value) { { id1: nil, id2: subtype.new(value2) } }

        it 'correctly returns nil rather than trying to dump their contents' do
          dumped_value = type.dump(value, opts)
          expect(dumped_value).to be_kind_of(::Hash)
          expect(dumped_value.keys).to match_array %w(id1 id2)
          expect(dumped_value['id1']).to be nil
          expect(dumped_value['id2']).to eq value2
        end
      end
    end
  end

  context '.requirements' do
    let(:type) { Attributor::Hash.construct(block) }

    context 'forces processing of lazy key initialization' do
      let(:block) do
        proc do
          key 'name', String
          requires 'name'
        end
      end

      it 'lists the requirements' do
        expect(type.requirements).to_not be_empty
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
        expect(errors).to have(2).items

        expect(errors).to include('Attribute $.key("one") received value: "one" is of the wrong type (got: String, expected: Attributor::Integer)')
        expect(errors).to include('Attribute $.value(:two) received value: :two is of the wrong type (got: Symbol, expected: Attributor::DateTime)')
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
        expect(errors).to have(3).items
        expect(errors).to include('Attribute $.key("not-optional") is required')
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
          expect(errors).to have(2).items
          %w(consistency availability).each do |name|
            expect(errors).to include("Key #{name} is required for $.")
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
          expect(errors).to have(1).items
          expect(errors).to include(
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
          expect(errors).to have(1).items
          expect(errors).to include('At most 2 keys out of ["consistency", "availability", "partitioning"] can be passed in for $. Found ["consistency", "availability", "partitioning"]')
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
          expect(errors).to have(1).items
          expect(errors).to include('Exactly 1 of the following keys ["consistency", "availability", "partitioning"] are required for $. Found 0 instead: []')
        end
        it 'complains if more than 1 in the group are set (false or true)' do
          errors = type.new('name' => 'CAP', 'consistency' => false, 'availability' => true).validate
          expect(errors).to have(1).items
          expect(errors).to include('Exactly 1 of the following keys ["consistency", "availability", "partitioning"] are required for $. Found 2 instead: ["consistency", "availability"]')
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
          expect(errors).to have(1).items
          expect(errors).to include('keys ["consistency", "availability"] are mutually exclusive for $.')
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
            requires.at_most(1).of 'consistency', 'availability', 'partitioning'
          end
        end

        it 'complains not all the listed elements are set (false or true)' do
          errors = type.new('name' => 'CAP').validate
          expect(errors).to have(1).items
          expect(errors).to include(
            'At least 1 keys out of ["consistency", "availability", "partitioning"] are required to be passed in for $. Found none'
          )
        end
      end
      context 'using a combo of things to test example gen' do
        let(:block) do
          proc do
            key :req1, String
            key :req2, String
            key :exc3, String
            key :exc4, String
            key :least1, String
            key :least2, String
            key :exact1, String
            key :exact2, String
            key :most1, String
            key :most2, String

            requires.all :req1, :req2
            requires.exclusive :exc3, :exc4
            requires.at_least(2).of :least1, :least2
            requires.exactly(1).of :exc3, :exact1, :exact2
            requires.at_most(1).of :most1, :most2
            requires.at_least(1).of :exc4, :exc3
          end
        end
        it 'comes up with a reasonably good set' do
          ex = type.example
          expect(ex.keys).to match([:req1, :req2, :exc3, :least1, :least2, :most1])
        end
        it 'it favors picking attributes with data' do
          ex = type.example(nil,{most2: "data"})
          expect(ex.keys).to match([:req1, :req2, :exc3, :least1, :least2, :most2])
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
        expect(attribute.example).to eq(example_hash)
      end
    end
  end

  context '.describe' do
    let(:example) { nil }
    subject(:description) { type.describe(example: example) }
    context 'for hashes with key and value types' do
      it 'describes the type correctly' do
        expect(description[:name]).to eq('Hash')
        expect(description[:key]).to eq(type: { name: 'Object', id: 'Attributor-Object', family: 'any' })
        expect(description[:value]).to eq(type: { name: 'Object', id: 'Attributor-Object', family: 'any' })
        expect(description).to_not have_key(:example)
      end
      context 'when there is a given example' do
        let(:example) { { 'one' => 1, two: 2 } }
        it 'uses it, even though there are not individual keys' do
          expect(description[:example]).to eq(example)
        end
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
        expect(description[:name]).to eq('Hash')
        expect(description[:key]).to eq(type: { name: 'String', id: 'Attributor-String', family: 'string' })
        expect(description).not_to have_key(:value)
      end

      it 'describes the type attributes correctly' do
        attrs = description[:attributes]

        expect(attrs['a string']).to eq(type: { name: 'String', id: 'Attributor-String', family: 'string' })
        expect(attrs['1']).to eq(type: { name: 'Integer', id: 'Attributor-Integer', family: 'numeric' }, options: { min: 1, max: 20 })
        expect(attrs['some_date']).to eq(type: { name: 'DateTime', id: 'Attributor-DateTime', family: 'temporal' })
        expect(attrs['defaulted']).to eq(type: { name: 'String', id: 'Attributor-String', family: 'string' }, default: 'default value')
      end

      it 'describes the type requirements correctly' do
        reqs = description[:requirements]
        expect(reqs).to be_kind_of(Array)
        expect(reqs.size).to be(5)
        expect(reqs).to include(type: :all, attributes: %w(1 some_date))
        expect(reqs).to include(type: :exclusive, attributes: %w(some_date defaulted))
        expect(reqs).to include(type: :at_least, attributes: ['a string', 'some_date'], count: 1)
        expect(reqs).to include(type: :at_most, attributes: ['a string', 'some_date'], count: 2)
        expect(reqs).to include(type: :exactly, attributes: ['a string', 'some_date'], count: 1)
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
          expect(req_all[:attributes]).to include('required string', 'some_date')
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
          expect(req_all).not_to be(nil)
          expect(req_all[:attributes]).to include('required string', 'required integer')
        end
      end

      context 'with an example' do
        let(:example) { type.example }

        it 'should have the matching example for each leaf key' do
          expect(description[:attributes].keys).to match_array type.keys.keys
          description[:attributes].each do |name, sub_description|
            expect(sub_description).to have_key(:example)
            val = type.attributes[name].dump(example[name])
            expect(sub_description[:example]).to eq val
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
      expect(output).to be_kind_of(::Hash)
      expect(output).to eq('one' => 2, '3' => 4)
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
        expect(subject).to be_kind_of(::Hash)
        expect(subject).to eq(hash)
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
        expect(type.dump(value)).to eq(expected)
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
          expect(type.dump(value)).to eq(expected)
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
            expect(type.dump(value)).to eq(expected)
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

        its(:keys) { should match_array [:one, :other] }
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
        expect(output['downcase']).to eq(1)
        expect(output['UPCASE']).to eq(2)
        expect(output['CamelCase']).to eq(3)
      end
      it 'has loaded the (internal) insensitive_map upon building the definition' do
        type.definition
        expect(type.insensitive_map).to be_kind_of(::Hash)
        expect(type.insensitive_map.keys).to match_array %w(downcase upcase camelcase)
      end
    end

    context 'when not defined' do
      let(:case_insensitive) { false }

      it 'skips the loading of the (internal) insensitive_map' do
        type.definition
        expect(type.insensitive_map).to be_nil
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
      its(:keys) { should match_array [:one, :two, :three] }

      it 'loads the extra keys' do
        expect(output[:one]).to eq('one')
        expect(output[:two]).to eq('two')
        expect(output[:three]).to eq('3')
      end

      its(:validate) { should be_empty }
    end

    context 'that should be grouped into a sub-hash' do
      before do
        type.keys do
          extra :options, Attributor::Hash.of(value: Integer)
        end
      end

      its(:keys) { should match_array [:one, :two, :options] }
      it 'loads the extra keys into :options sub-hash' do
        expect(output[:one]).to eq('one')
        expect(output[:two]).to eq('two')
        expect(output[:options]).to eq(three: 3)
      end
      its(:validate) { should be_empty }

      context 'with an options value already provided' do
        its(:keys) { should match_array [:one, :two, :options] }
        let(:input) { { one: 'one', three: 3, options: { four: 4 } } }

        it 'loads the extra keys into :options sub-hash' do
          expect(output[:one]).to eq('one')
          expect(output[:two]).to eq('two')
          expect(output[:options]).to eq(three: 3, four: 4)
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
          expect(hash).not_to have_key('others')
          hash.set 'foo', 'bar'
          expect(hash['others']).to have_key('foo')
          expect(hash).to have_key('others')
          expect(hash['others']['foo']).to eq('bar')
        end

        it 'loads values before saving into the contents' do
          hash.set 'chicken', chicken
          expect(hash['chicken']).to be_a(Chicken)
        end
      end

      context '#get' do
        before do
          hash['chicken'] = chicken
          expect(hash['chicken']).to eq(chicken)
        end

        it 'loads and updates the saved value' do
          expect(hash.get('chicken')).to be_a(Chicken)
          expect(hash['chicken']).to be_a(Chicken)
        end

        it 'retrieves values from an "extra" key' do
          bar = double('bar')
          hash.set 'foo', bar
          expect(hash.get('others').get('foo')).to be(bar)

          expect(hash.get('foo')).to be(bar)
        end

        it 'does not set a key that is unset' do
          expect(hash).not_to have_key('id')
          expect(hash.get('id')).to be(nil)
          expect(hash).not_to have_key('id')
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

  context Attributor::InvalidDefinition do
  end
end
