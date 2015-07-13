require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Class do

  subject(:type) { Attributor::Class }

  context '.native_type' do
    it "returns Regexp" do
      type.native_type.should be(::Class)
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

      ['Object', '::Object', '::Hash', 'Attributor::Struct'].each do |value|
        it "loads '#{value}' as #{eval(value)}" do
          type.load(value).should eq(eval(value))
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
