require_relative '../spec_helper'

describe Attributor::Collection do

  subject(:type) { Attributor::Collection }

  context '.of' do

    [Attributor::Integer, Attributor::Struct].each do |element_type|
      it "returns an anonymous class with correct element type #{element_type}" do
        klass = type.of(element_type)
        klass.should be_a(::Class)
        klass.instance_variable_get(:@element_type).should == element_type
      end
    end

    [::Integer, ::String, ::Object].each do |element_type|
      it "raises when given invalid element type #{element_type}" do
        element_type = ::String # Must be an Attributor::Type
        expect { klass = type.of(element_type) }.to raise_error(Attributor::AttributorException)
      end
    end
  end

  context '.native_type' do
    it "returns Array" do
      type.native_type.should be(::Array)
    end
  end

  context '.decode_json' do
    context 'for valid JSON strings' do
      [
          '[]',
          '[1,2,3]',
          '["alpha", "omega", "gamma"]',
          '["alpha", 2, 3.0]'
      ].each do |value|
        it "parses JSON string as array when incoming value is #{value.inspect}" do
          type.decode_json(value).should == JSON.parse(value)
        end
      end
    end

    context 'for invalid JSON strings' do
      [
          '{}',
          'foobar',
          '2',
          '',
          2,
          nil
      ].each do |value|
        it "parses JSON string as array when incoming value is #{value.inspect}" do
          expect {
            type.decode_json(value)
          }.to raise_error(Attributor::AttributorException)
        end
      end
    end

  end

  context '.load' do
    context 'with unspecified element type' do
      context 'for valid values' do
        [
          [],
          [1,2,3],
          [Object.new, [1,2], nil, true]
        ].each do |value|
          it "returns value when incoming value is #{value.inspect}" do
            type.load(value).should == value
          end
        end
      end

      context 'for invalid values' do
        [nil, 1, Object.new, false, true, 3.0].each do |value|
          it "raises error when incoming value is #{value.inspect}" do
            expect { type.load(value).should == value }.to raise_error(Attributor::AttributorException)
          end
        end
      end
    end

    context 'with Attributor::Type element type' do
      context 'for valid values' do
        {
          Attributor::String   => ["foo", "bar"],
          Attributor::Integer  => [1, "2", 3],
          Attributor::Float    => [1.0, "2.0", Math::PI, Math::E],
          Attributor::DateTime => ["2001-02-03T04:05:06+07:00", "Sat, 3 Feb 2001 04:05:06 +0700"],
          ::Chicken            => [::Chicken.new, ::Chicken.new]
        }.each do |element_type, value|
          it "returns loaded value when element_type is #{element_type} and value is #{value.inspect}" do
            expected_result = value.map {|v| element_type.load(v)}
            type.of(element_type).load(value).should == expected_result
          end
        end
      end

      context 'for invalid values' do
        {
          ::String  => ["foo", "bar"],
          ::Object  => [::Object.new],
          ::Chicken => [::Turkey.new]
        }.each do |element_type, value|
          it "raises error when element_type is #{element_type} and value is #{value.inspect}" do
            expect { type.of(element_type).load(value).should == value }.to raise_error(Attributor::AttributorException)
          end
        end
      end
    end

    context 'with Attributor::Struct element type' do
      context 'for valid values' do
        it "succeeds"
      end

      context 'for invalid values' do
        it "raises"
      end
    end
  end

  context '.validate' do
    context 'for valid Array values' do
      it "returns no errors for []" do
        type.validate([], nil, nil).should == []
      end
    end

    context 'for invalid Array values' do
      it "returns errors for [1,2]" do
        errors = type.validate([1,2], "monkey", nil)
        errors.should_not be_empty
        errors.include?("Collection monkey[0] is not an Attributor::Type").should be_true
        errors.include?("Collection monkey[1] is not an Attributor::Type").should be_true
      end

      it "returns errors for [nil]" do
        errors = type.validate([nil], "dog", nil)
        errors.should_not be_empty
        errors.include?("Collection dog[0] is not an Attributor::Type").should be_true
      end

      it "returns errors for [1.0, Object.new]" do
        errors = type.validate([1.0, Object.new], "cat", nil)
        errors.should_not be_empty
        errors.include?("Collection cat[0] is not an Attributor::Type").should be_true
        errors.include?("Collection cat[1] is not an Attributor::Type").should be_true
      end
    end
  end

  context '.example' do
    it "returns an Array" do
      value = type.example({})
      value.should be_a(::Array)
    end

    Attributor::BASIC_TYPES.each do |element_type|
      it "returns an Array of native types of #{element_type}" do
        value = Attributor::Collection.of(element_type).example({})
        value.all? { |element| element_type.valid_type?(element) }.should be_true
      end
    end
  end
end

