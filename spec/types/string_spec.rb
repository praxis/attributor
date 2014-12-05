require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::String do

  subject(:type) { Attributor::String }

  context '.native_type' do
    it "returns String" do
      type.native_type.should be(::String)
    end
  end

  context '.example' do
    it "should return a valid String" do
      type.example(options:{regexp: /\w\d{2,3}/}).should be_a(::String)
    end

    it "should return a valid String" do
      type.example.should be_a(::String)
    end

    it 'handles regexps that Randexp can not' do
      pending 'resolution of #72' do
        regex = /\w+(,\w+)*/
        expect {
          val = Attributor::String.example(options:{regexp: regex})
          val.should be_a(::String)
        }.to_not raise_error
      end
    end

  end

  context '.load' do
    let(:value) { nil }

    it 'returns nil for nil' do
      type.load(nil).should be(nil)
    end

    context 'for incoming String values' do

      it 'returns the incoming value' do
        ['', 'foo', '0.0', '-1.0', '1.0', '1e-10', 1].each do |value|
          type.load(value).should eq(String(value))
        end
      end
    end

  end

  context 'for incoming Symbol values' do
    let(:value) { :something }
    it 'returns the stringified-value' do
      type.load(value).should == value.to_s
    end
  end

end
