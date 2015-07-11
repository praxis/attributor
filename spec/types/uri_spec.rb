require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::URI do

  subject(:type) { Attributor::URI }

  its(:native_type) { should be ::URI::Generic }

  context '.example' do
    it 'returns a valid URI' do
      expect(type.example).to_be kind_of(URI)
    end

    context 'when path option specified' do
      it 'returns a generic URI conforming to the regex in path' do
        expect(type.example(nil, path: /^\//).to_s).to match(/^\//)
      end
    end
  end
end
