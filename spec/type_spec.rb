require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Attributor::Type do


  subject(:test_type) { AttributeType }

  let(:attribute_options) { Hash.new }
  let(:attribute_attributes) { Hash.new }

  let(:attribute) do
    double "attribute",
      :options => attribute_options,
      :attributes => attribute_attributes
  end


  its(:native_type) { should be(::String) }


  context 'load' do
    let(:value) { "one" }

    let(:context) { nil }

    context "when given a value that is of native_type" do
      it 'returns the value' do
        test_type.load(value).should be(value)
      end
    end


    context "when given a value that is not of native_type" do
      let(:value) { 1 }

      it 'raises an exception' do
        expect { test_type.load(value) }.to raise_error(/is not of type/)
      end


    end

  end


  context 'validate' do
    let(:context) { 'some_attribute'}

    let(:attribute_options) { {} }

      let(:attribute) { double("some_attribute", :options => attribute_options)}
      subject(:errors) { test_type.validate(value, context, attribute) }

    context 'min and max' do
      let(:min) { 10 }
      let(:max) { 100}

      let(:attribute_options) { {:min => min, :max => max} }



      context "with a value <= min" do
        let(:value) { 1 }

        it { should_not be_empty }
        it 'returns the correct error message' do
          errors.first.should =~ /value is smaller than the allowed min/
        end
      end

      context "with a value >= max" do
        let(:value) { 1000 }
        it { should_not be_empty }
        it 'returns the correct error message' do
          errors.first.should =~ /value is larger than the allowed max/
        end

      end

      context 'with a value within the range' do
        let(:value) { 50 }
        it { should be_empty }
      end


    end



     context 'regexp' do
      let(:regexp) { /dog/ }
      let(:attribute_options) { {:regexp => regexp} }

      context 'with a value that matches' do
        let(:value) { 'bulldog' }

        it { should be_empty }
      end


      context 'with a value that does not match' do
        let(:value) { 'chicken' }
        it { should_not be_empty}
        it 'returns the correct error message' do
          errors.first.should =~ /value does not match regexp/
        end
      end

     end


  end


  context 'example' do

  end



  # context 'for a Model' do
  #   class TestModelType
  #     include Attributor::Model
  #     def self.native_type
  #       ::Integer
  #     end

  #     def self.decode(value,attribute)
  #        p 'in self decode'
  #        case value
  #        when String
  #          value.to_i
  #        else
  #          raise "unknown type for value #{value.inspect}"
  #        end
  #      end

  #   end

  #   subject(:test_model_type) { TestModelType }

  #   let(:value) { "1" }
  #   let(:context) { nil }

  #   it 'loads magically' do
  #     load_value, load_errors = test_model_type.load(value, context,attribute)
  #   end

  # end

end
