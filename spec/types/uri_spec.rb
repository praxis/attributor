require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::URI do
  subject(:type) { Attributor::URI }

  it 'it is not Dumpable' do
    type.new.is_a?(Attributor::Dumpable).should_not be(true)
  end

  its(:native_type) { should be ::URI::Generic }

  context '.example' do
    it 'returns a valid URI' do
      expect(type.example).to be_kind_of(URI)
    end
  end

  context '.dump' do
    let(:example) { type.example }
    it 'uses the underlying URI to_s' do
      expect(type.dump(example)).to eq(example.to_s)
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
    let(:uri) { URI.parse('http://www.example.com/something/foo') }
    let(:attribute) { nil }
    subject(:validate) { type.validate(uri, ['root'], attribute) }

    context 'when given a valid URI' do
      it 'does not return any errors' do
        expect(subject).to be_empty
      end

      context 'when given a path option' do
        let(:attribute) { Attributor::Attribute.new(type, path: %r{^/}) }

        context 'given a URI that matches the path regex' do
          it 'does not return any errors' do
            expect(subject).to be_empty
          end
        end

        context 'given a URI that does not match the path regex' do
          let(:uri) { URI.parse('www.example.com/something/foo') }
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
        let(:options) { { path: Regexp.new('a-z') } }
        it 'checks successfully' do
          expect(subject).to be_kind_of(Attributor::Attribute)
        end
      end

      context 'given any definition other than regex' do
        let(:options) { { path: 1 } }
        it 'raises an exception' do
          expect { subject }.to raise_error(Attributor::AttributorException)
        end
      end
    end

    context 'for any other option' do
      let(:options) { { something: 1 } }
      it 'raises an exception' do
        expect { subject }.to raise_error(Attributor::AttributorException)
      end
    end
  end
end
