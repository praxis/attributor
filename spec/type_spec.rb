require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::Type do
  subject(:test_type) do
    Class.new do
      include Attributor::Type
      def self.native_type
        ::String
      end

      def self.name
        'Testing'
      end

      def self.family
        'testing'
      end
    end
  end

  let(:attribute_options) { Hash.new }
  let(:attribute_attributes) { Hash.new }

  let(:attribute) do
    double 'attribute',
           options: attribute_options,
           attributes: attribute_attributes
  end

  its(:native_type) { should be(::String) }
  its(:id) { should eq('Testing') }

  context 'anonymous' do
    its(:anonymous?) { should be(false) }
    it 'is true for nameless-types' do
      klass = Class.new do
        include Attributor::Type
      end
      expect(klass.anonymous?).to be(true)
    end
    it 'can be set to true explicitly' do
      klass = Class.new(test_type) do
        anonymous_type
      end
      expect(klass.anonymous?).to be(true)
    end
  end

  context 'load' do
    let(:value) { nil }
    let(:context) { nil }

    context 'when given a nil value' do
      it 'always successfully returns it (i.e., you can always load nil)' do
        expect(test_type.load(value)).to be(value)
      end
    end

    context 'when given a value that is of native_type' do
      let(:value) { 'one' }
      it 'returns the value' do
        expect(test_type.load(value)).to be(value)
      end
    end

    context 'when given a value that is not of native_type' do
      let(:value) { 1 }
      let(:context) { %w(top sub) }

      it 'raises an exception' do
        expect { test_type.load(value, context) }.to raise_error(Attributor::IncompatibleTypeError, /cannot load values of type Fixnum.*while loading top.sub/)
      end
    end
  end

  context 'validate' do
    let(:context) { ['some_attribute'] }

    let(:attribute_options) { {} }

    let(:attribute) { double('some_attribute', options: attribute_options) }
    subject(:errors) { test_type.validate(value, context, attribute) }

    context 'min and max' do
      let(:min) { 10 }
      let(:max) { 100 }

      let(:attribute_options) { { min: min, max: max } }

      context 'with a value <= min' do
        let(:value) { 1 }

        it { should_not be_empty }
        it 'returns the correct error message' do
          expect(errors.first).to match(/value \(#{value}\) is smaller than the allowed min/)
        end
      end

      context 'with a value >= max' do
        let(:value) { 1000 }
        it { should_not be_empty }
        it 'returns the correct error message' do
          expect(errors.first).to match(/value \(#{value}\) is larger than the allowed max/)
        end
      end

      context 'with a value within the range' do
        let(:value) { 50 }
        it { should be_empty }
      end
    end

    context 'regexp' do
      let(:regexp) { /dog/ }
      let(:attribute_options) { { regexp: regexp } }

      context 'with a value that matches' do
        let(:value) { 'bulldog' }

        it { should be_empty }
      end

      context 'with a value that does not match' do
        let(:value) { 'chicken' }
        it { should_not be_empty }
        it 'returns the correct error message' do
          expect(errors.first).to match(/value \(#{value}\) does not match regexp/)
        end
      end
    end
  end

  context 'example' do
  end

  context 'id' do
    it 'works for built-in types' do
      expect(Attributor::String.id).to eq('Attributor-String')
    end

    it 'returns nil for anonymous types' do
      type = Class.new(Attributor::Model)
      expect(type.id).to eq(nil)
    end
  end

  context 'describe' do
    let(:example) { 'Foo' }
    subject(:description) { test_type.describe }
    it 'outputs the type name' do
      expect(description[:name]).to eq(test_type.name)
    end
    it 'outputs the type id' do
      expect(description[:id]).to eq(test_type.name)
    end

    context 'with an example' do
      subject(:description) { test_type.describe(example: example) }
      it 'includes it in the :example key' do
        expect(description).to have_key(:example)
        expect(description[:example]).to be(example)
      end
    end

    context 'when anonymous' do
      it 'reports true in the output when set (to true default)' do
        anon_type = Class.new(test_type) { anonymous_type }
        expect(anon_type.describe).to have_key(:anonymous)
        expect(anon_type.describe[:anonymous]).to be(true)
      end
      it 'reports false in the output when set false explicitly' do
        anon_type = Class.new(test_type) { anonymous_type false }
        expect(anon_type.describe).to have_key(:anonymous)
        expect(anon_type.describe[:anonymous]).to be(false)
      end
    end
  end
end
