require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Regexp do
  subject(:type) { Attributor::Regexp }

  it 'it is not Dumpable' do
    expect(type.new.is_a?(Attributor::Dumpable)).not_to be(true)
  end

  its(:native_type) { should be(::Regexp) }
  its(:example) { should be_a(::String) }
  its(:family) { should eq 'string' }

  context '.load' do
    let(:value) { nil }

    it 'returns nil for nil' do
      expect(type.load(nil)).to be(nil)
    end

    context 'for incoming String values' do
      { 'foo' => /foo/, '^pattern$' => /^pattern$/ }.each do |value, expected|
        it "loads '#{value}' as #{expected.inspect}" do
          expect(type.load(value)).to eq(expected)
        end
      end
    end
  end
end
