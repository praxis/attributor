require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::URI do

  subject(:type) { Attributor::URI }

  its(:native_type) { should be ::URI::Generic }

  context '.example' do
    it 'returns a valid URI' do
      expect(type.example).to be_kind_of(URI)
    end

    context 'when path option specified' do
      it 'returns a generic URI conforming to the regex in path' do
        expect(type.example(nil, path: /^\//).to_s).to match(/^\//)
      end
    end
  end

  context '.load' do
    subject(:load) { type.load(value) }

    context 'given a nil' do
      let(:value) { nil }
      it 'returns a nil' do
        expect(subject).to be_nil
      end
    end

    context 'given a string' do
      let(:value) { 'string' }
      it 'returns a URI object' do
        expect(subject).to be_kind_of(URI)
      end
    end

    context 'given a URI object' do
      let(:value) { URI.parse('string') }
      it 'returns itself' do
        expect(subject).to eq(value)
      end
    end

    context 'given a value not its native_type' do
      let(:value) { Class.new }
      it 'raises an error' do
        expect { subject }.to raise_error(Attributor::CoercionError)
      end
    end
  end

  context '.validate' do
    let(:string) { 'http://www.example.com' }
    let(:attribute) { nil }
    subject(:validate) { type.validate(string, ['root'], attribute) }

    context 'when given a string' do
      it 'does not return any errors' do
        expect(subject).to be_empty
      end

      context 'when given a path option' do
        let(:attribute) { Attributor::Attribute.new(type, path: /^\//) }

        context 'given a string that matches the regex' do
          let(:string) { '/path/to/something' }
          it 'does not return any errors' do
            expect(subject).to be_empty
          end
        end

        context 'given a string that does not match the regex' do
          it 'returns an errors array' do
            expect(subject).to_not be_empty
          end
        end
      end
    end
  end

  context '.check_option!' do
    let(:options) { {} }
    subject(:attribute) { Attributor::Attribute.new(type, options) }

    context 'for path option' do
      context 'given a regex definition' do
        let(:options) { {path: Regexp.new('a-z')} }
        it 'checks successfully' do
          expect(subject).to be_kind_of(Attributor::Attribute)
        end
      end

      context 'given any definition other than regex' do
        let(:options) { {path: 1} }
        it 'raises an exception' do
          expect { subject }.to raise_error(Attributor::AttributorException)
        end
      end
    end

    context 'for any other option' do
      let(:options) { {something: 1} }
      it 'raises an exception' do
        expect { subject }.to raise_error(Attributor::AttributorException)
      end
    end
  end
end
