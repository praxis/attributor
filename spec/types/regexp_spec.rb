require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Regexp do

  subject(:type) { Attributor::Regexp }

  context '.native_type' do
    it "returns Regexp" do
      type.native_type.should be(::Regexp)
    end
  end

  context '.example' do
    it "should return a valid String" do
      type.example.should be_a(::String)
    end
  end

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

      context 'given options' do
        it 'loads String with a single option' do
          type.load('foobar',{regexp_opts: Regexp::IGNORECASE}).should eq(/foobar/i)
        end

        it 'loads String with multiple options' do
          type.load('foobar',{regexp_opts: Regexp::MULTILINE | Regexp::EXTENDED}).should eq(/foobar/mx)
        end
      end
    end
  end

  context '.family' do
    it 'returns "string" as the family' do
      type.family.should == 'string'
    end
  end
end
