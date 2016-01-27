require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe 'Dumpable' do

  context 'for classes forgetting to implement #dump' do
    let(:type) {
      Class.new do
        include Attributor::Dumpable
      end
     }

    it 'gets an exception' do
      expect{ type.new.dump }.to raise_exception(NotImplementedError)
    end
  end

  context 'for classes properly implementing #dump' do
    let(:type) {
      Class.new do
        include Attributor::Dumpable
        def dump
        end
      end
     }

    it 'do not get the base exception' do
      expect{ type.new.dump }.to_not raise_exception(NotImplementedError)
    end
  end
end
