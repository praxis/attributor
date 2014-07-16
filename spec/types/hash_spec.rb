require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Attributor::Hash do

  subject(:type) { Attributor::Hash }

  its(:native_type) { should be(type) }

  context '.example' do
    context 'for a simple hash' do
      it 'returns an empty Hash' do
        type.example.should eq(Hash.new)
      end
    end

    context 'for a typed hash' do
      subject(:example){ Attributor::Hash.of( value: Integer).example}
      it 'returns a hash with keys and/or values of the right type' do
        example.should be_kind_of(::Hash)
        example.keys.size.should > 0
        example.values.all?{|v| v.kind_of? Integer}.should be(true)
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
      subject(:type){ Attributor::Hash.of( value: Integer) }
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

        subject(:type) { Attributor::Hash.construct(block, key_type: String) }
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
          Attributor::Hash.construct(block, key_type: String).keys
        }.to raise_error(/Invalid key: :some_date, must be instance of String/)
      end

    end
  end

  context '.check_option!' do
    it 'accepts key_type:' do
      subject.check_option!(:key_type, String).should == :ok
    end
    it 'accepts value_type'  do
      subject.check_option!(:value_type, Object).should == :ok
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
end
