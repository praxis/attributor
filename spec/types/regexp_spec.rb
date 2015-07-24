require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Regexp do

  subject(:type) { Attributor::Regexp }

  its(:native_type) { should be(::Regexp) }
  its(:example) { should be_a(::String) }
  its(:family) { should == 'string' }

  context '.load' do
    let(:value) { nil }

    it 'returns nil for nil' do
      type.load(nil).should be(nil)
    end

    context 'for incoming String values' do

      { 'foo' => /foo/, '^pattern$' => /^pattern$/ }.each do |value, expected|
        it "loads '#{value}' as #{expected.inspect}" do
          type.load(value).should eq(expected)
        end
      end

    end
  end
end
