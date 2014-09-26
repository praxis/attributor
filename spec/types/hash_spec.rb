require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Attributor::Hash do

  subject(:type) { Attributor::Hash }

  its(:native_type) { should be(type) }
  its(:key_type) { should be(Attributor::Object) }
  its(:value_type) { should be(Attributor::Object) }

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
      subject(:example){ Attributor::Hash.of(value: Integer).example}

      it 'returns a hash with keys and/or values of the right type' do
        example.should be_kind_of(Attributor::Hash)
        example.keys.size.should > 0
        example.values.all? {|v| v.kind_of? Integer}.should be(true)
      end
    end
    context 'using a non array context' do
      it 'should work for hashes with key/value types' do
        expect{ Attributor::Hash.of(key:String,value:String).example("Not an Array") }.to_not raise_error
      end
      it 'should work for hashes with keys defined' do
        block = proc { key 'a string', String }
        hash = Attributor::Hash.of(key:String).construct(block)

        expect{ hash.example("Not an Array") }.to_not raise_error
      end
    end
  end

  context '.load' do
    let(:value) { {one: 'two', three: 4} }
    subject(:hash) { type.load(value) }

    context 'for a simple hash' do
      it { should eq(value) }
      it 'equals the hash' do
        hash.should eq value
        hash[:one].should eq('two')
        hash[:three].should eq(4)
      end
    end

    context 'for a JSON encoded hash' do
      let(:value_as_hash) { {'one' => 'two', 'three' => 4} }
      let(:value) { JSON.dump( value_as_hash ) }
      it 'deserializes and converts it to a real hash' do
        hash.should eq(value_as_hash)
        hash['one'].should eq 'two'
      end
    end

    context 'for a typed hash' do
      subject(:type){ Attributor::Hash.of(key: String, value: Integer)}
      context 'with good values' do
        let(:value) { {one: '1', 'three' => 3} }
        it 'coerces good values into the correct types' do
          hash.should eq({'one' => 1, 'three' => 3})
          hash['one'].should eq(1)
        end
      end

      context 'with incompatible values' do
        let(:value) { {one: 'two', three: 4} }
        it 'fails' do
          expect{
            type.load(value)
          }.to raise_error(/invalid value for Integer/)
        end
      end

    end

    context 'for a partially typed hash' do
      subject(:type){ Attributor::Hash.of(value: Integer) }
      context 'with good values' do
        let(:value) { {one: '1', [1,2,3] => 3} }
        it 'coerces only values into the correct types (and leave keys alone)' do
          hash.should eq({:one => 1, [1,2,3] => 3})
        end
      end
    end
  end


  context '.of' do
    context 'specific key and value types' do
      let(:key_type){ String }
      let(:value_type){ Integer }

      subject(:type) { Attributor::Hash.of(key: key_type, value: value_type) }

      it { should be_a(::Class) }
      its(:ancestors) { should include(Attributor::Hash) }
      its(:key_type) { should == Attributor::String }
      its(:value_type) { should == Attributor::Integer }

      context '.load' do
        let(:value) { {one: '2', 3 => 4} }

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

    it { should_not be(Attributor::Hash)
         }

    context 'loading' do
      let(:date) { DateTime.parse("2014-07-15") }
      let(:value) do
        {'a string' => 12, '1' => '2', :some_date => date.to_s}
      end

      subject(:hash) { type.load(value)}

      it 'loads' do
        hash['a string'].should eq('12')
        hash['1'].should eq(2)
        hash[:some_date].should eq(date)
        hash['defaulted'].should eq('default value')
      end

      context 'with unknown keys in input' do
        it 'raises an error' do
          expect {
            type.load({'other_key' => :value})
          }.to raise_error(Attributor::AttributorException)
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
          {'a string' => 12, 1 => '2', :some_date => date.to_s}
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
        expect {
          Attributor::Hash.of(key:String).construct(block).keys
        }.to raise_error(/Invalid key: :some_date, must be instance of String/)
      end

    end
  end

  context '.check_option!' do
    context ':case_insensitive_load' do

      it 'is valid when key_type is a string' do
        Attributor::Hash.of(key:String).check_option!(:case_insensitive_load, true).should == :ok
      end

      it 'is invalid when key_type is non-string' do
        expect {
          Attributor::Hash.of(key:Integer).check_option!(:case_insensitive_load, true)
        }.to raise_error(Attributor::AttributorException, /:case_insensitive_load may not be used/)
      end

    end
    it 'rejects unknown options'  do
      subject.check_option!(:bad_option, Object).should == :unknown
    end

  end

  context '.dump' do

    let(:value) { {one: 1, two: 2} }
    let(:opts) { {} }

    context 'for a simple (untyped) hash' do
      it 'returns the untouched hash value' do
        type.dump(value, opts).should eq(value)
      end
    end

    context 'for a typed hash' do
      let(:value1) { {first: "Joe", last: "Moe"} }
      let(:value2) { {first: "Mary", last: "Foe"} }
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
        subtype.should_receive(:dump).exactly(2).times.and_call_original
        dumped_value = type.dump(value, opts)
        dumped_value.should be_kind_of(::Hash)
        dumped_value.keys.should =~ [:id1,:id2]
        dumped_value.values.should have(2).items
        value[:id1].should be_kind_of subtype
        value[:id2].should be_kind_of subtype
        dumped_value[:id1].should == value1
        dumped_value[:id2].should == value2
      end

    end
  end

  context '#validate' do
    context 'for a key and value typed hash' do
      let(:key_type){ Integer }
      let(:value_type){ DateTime }

      let(:type) { Attributor::Hash.of(key: key_type, value: value_type) }
      subject(:hash) { type.new('one' => :two) }

      it 'returns errors for key and value' do
        errors = hash.validate
        errors.should have(2).items

        errors.should include("Attribute $.key(\"one\") received value: \"one\" is of the wrong type (got: String, expected: Attributor::Integer)")
        errors.should include("Attribute $.value(:two) received value: :two is of the wrong type (got: Symbol, expected: Attributor::DateTime)")

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

      let(:values) { {'integer' => 'one', 'datetime' => 'now' } }
      subject(:hash) { type.new(values) }

      it 'validates the keys' do
        errors = hash.validate
        errors.should have(3).items
        errors.should include("Attribute $.key(\"not-optional\") is required")
      end

    end

  end

  context 'in an Attribute' do
    let(:options) { {} }
    subject(:attribute) { Attributor::Attribute.new(Attributor::Hash, options)}

    context 'with an example option that is a proc' do
      let(:example_hash) { {:key => "value"} }
      let(:options) { { example: proc { example_hash } } }
      it 'uses the hash' do
        attribute.example.should be(example_hash)
      end
    end

  end

  context '.describe' do
    subject(:description) { type.describe }
    context 'for hashes with key and value types' do
      it 'describes the type correctly' do
        description[:name].should eq('Hash')
        description[:key].should eq(type:{name: 'Object'})
        description[:value].should eq(type:{name: 'Object'})
      end
    end

    context 'for hashes specific keys defined' do
      let(:block) do
        proc do
          key 'a string', String
          key '1', Integer, min: 1, max: 20
          key 'some_date', DateTime
          key 'defaulted', String, default: 'default value'
        end
      end

      let(:type) { Attributor::Hash.of(key: String).construct(block) }

      it 'describes the type correctly' do
        description[:name].should eq('Hash')
        description[:key].should eq(type:{name: 'String'})
        description.should_not have_key(:value)

        keys = description[:keys]

        keys['a string'].should eq(type: {name: 'String'} )
        keys['1'].should eq(type: {name: 'Integer'}, options: {min: 1, max: 20}  )
        keys['some_date'].should eq(type: {name: 'DateTime' }) #
        keys['defaulted'].should eq(type: {name: 'String'}, default: 'default value')
      end
    end
  end

  context '#dump' do
    let(:key_type){ String }
    let(:value_type){ Integer }
    let(:hash) { {one: '2', 3 => 4} }
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
      let(:hash) { {one: value_type.example} }

      it 'works too' do
        #pp output
      end

    end
  end

  context 'with case_insensitive_load option for string keys' do
    let(:block) do
      proc do
        key 'downcase', Integer
        key 'UPCASE', Integer
        key 'CamelCase', Integer
      end
    end

    let(:type) { Attributor::Hash.of(key: String).construct(block, case_insensitive_load: true) }

    let(:input) { {'DOWNCASE' => 1, 'upcase' => 2, 'CamelCase' => 3} }

    subject(:output) { type.load(input) }

    it 'maps the incoming keys to defined keys, regardless of case' do
      output['downcase'].should eq(1)
      output['UPCASE'].should eq(2)
      output['CamelCase'].should eq(3)
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

    let(:input) { {one: 'one', three: 3} }
    subject(:output) { type.load(input) }

    context 'that should be saved at the top level' do
      its(:keys) { should =~ [:one, :two, :three] }

      it 'loads the extra keys' do
        output[:one].should eq('one')
        output[:two].should eq('two')
        output[:three].should eq('3')
      end
      
      its( :validate ){ should be_empty }
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
        output[:options].should eq({three: 3})
      end
      its( :validate ){ should be_empty }

      context 'with an options value already provided' do
        its(:keys) { should =~ [:one, :two, :options] }
        let(:input) { {one: 'one', three: 3, options: {four: 4}} }

        it 'loads the extra keys into :options sub-hash' do
          output[:one].should eq('one')
          output[:two].should eq('two')
          output[:options].should eq({three: 3, four: 4})
        end
        its( :validate ){ should be_empty }

      end
    end

  end

end
