require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'backports'

describe Attributor::Class do

  subject(:type) { Attributor::Class }

  context '.native_type' do
    it "returns Regexp" do
      type.native_type.should be(::Class)
    end
  end

  context '.example' do
    it "returns a valid String" do
      type.example.should be_a(::String)
    end

    context 'when created using .of method' do
      let(:klass) { Integer }
      subject(:type) { Attributor::Class.of(klass) }

      it "returns the class specified" do
        type.example.should eq(klass.to_s)
      end
    end
  end

  context '.load' do
    let(:value) { nil }

    context 'for incoming String values' do
      ['Object', '::Object', '::Hash', 'Attributor::Struct'].each do |value|
        it "loads '#{value}' as #{eval(value)}" do
          type.load(value).should eq(value.constantize)
        end
      end
    end

    context 'when created using .of method' do
      let(:klass) { Integer }
      subject(:type) { Attributor::Class.of(klass) }

      it "loads 'Integer' as Integer" do
        type.load('Integer').should eq(Integer)
      end

      it "returns specified class for nil" do
        type.load(nil).should be(klass)
      end

      it "raises when given a class that doesn't match specified class" do
        expect { type.load('Float') }.to raise_exception(Attributor::LoadError)
      end
    end

    it 'returns nil for nil' do
      type.load(nil).should be(nil)
    end

    it 'raises when given a non-String' do
    end
  end

  context '.family' do
    it 'returns "string" as the family' do
      type.family.should == 'string'
    end
  end
end
