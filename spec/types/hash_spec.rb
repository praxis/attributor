require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')


describe Attributor::Hash do

  subject(:type) { Attributor::Hash }

  context '.native_type' do
    it 'should return Hash' do
      type.native_type.should be(::Hash)
    end
  end

  context '.example' do
    context 'for a simple hash' do
      it 'should return an empty Hash' do
        type.example.should eq(Hash.new)
      end
    end
    
    context 'for a typed hash' do
      subject(:example){ Attributor::Hash.of( value: Integer).example}
      it 'should return a hash with keys and/or values of the right type' do
        example.should be_kind_of(::Hash)
        example.keys.size.should > 0
        example.values.all?{|v| v.kind_of? Integer}.should be(true)
      end
    end
  end

  context '.load' do
    let(:value) { {one: 'two', three: 4} }

    context 'for a simple hash' do
      it 'returns the hash' do
        type.load(value).should be(value)
      end
    end
    
    context 'for a JSON encoded hash' do
      let(:value_as_hash) { {'one' => 'two', 'tree' => 4} }
      let(:value) { JSON.dump( value_as_hash ) }
      it 'deserializes and converts it to a real hash' do
        type.load(value).should eq(value_as_hash)
      end
    end
    
    context 'for a typed hash' do
      subject(:type){ Attributor::Hash.of(key: String, value: Integer)}
      context 'with good values' do
        let(:value) { {one: '1', 'three' => 3} }
        it 'should coerce good values into the correct types' do
          type.load(value).should == {'one' => 1, 'three' => 3}
        end 
      end

      context 'with incompatible values' do
        let(:value) { {one: 'two', three: 4} }
        it 'should fail' do
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
        it 'should coerce only values into the correct types (and leave keys alone)' do
          type.load(value).should == {:one => 1,  [1,2,3] => 3 }
        end 
      end
    end
  end
  
  context '.of' do
    let(:key_type){ String }
    let(:value_type){ Integer }

    context 'specific key and value types' do
      it 'saves the passed values to the created class' do      
        klass = type.of(key: key_type, value: value_type)
        klass.should be_a(::Class)
        klass.ancestors.should include(Attributor::Hash) 
        klass.key_type.should == Attributor::String
        klass.value_type.should == Attributor::Integer
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
      it 'should return the untouched hash value' do
      type.dump(value, opts).should eq(value)
      end
    end
    
    context 'for a typed hash' do
      let(:value1) { {first: "Joe", last: "Moe"} }
      let(:value2) { {first: "Mary", last: "Foe"} }
      let(:value) { { id1: subtype.new(value1), id2: subtype.new(value2) } }
      let(:subtype) do
        c = Class.new(Attributor::Model) do
          attributes do
            attribute :first, String
            attribute :last, String
          end
        end
        c
      end
      let(:type) { Attributor::Hash.of(key: String, value: subtype) }
      
      it 'should return a hash with the dumped values and keys' do
        subtype.should_receive(:dump).exactly(2).times.and_call_original
        dumped_value = type.dump( value, opts ) 
        dumped_value.should be_kind_of( ::Hash )
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

