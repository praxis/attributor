require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')
require 'backports'

describe Attributor::Class do
  subject(:type) { Attributor::Class }

  it 'it is not Dumpable' do
    type.new.is_a?(Attributor::Dumpable).should_not be(true)
  end

  its(:native_type) { should be(::Class) }
  its(:family) { should == 'string' }

  context '.example' do
    its(:example) { should be_a(::String) }

    context 'when created using .of method' do
      let(:klass) { Integer }
      subject(:type) { Attributor::Class.of(klass) }

      its(:example) { should eq(klass.to_s) }
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

    context 'for incoming Class values' do
      [Object, ::Object, ::Hash, Attributor::Struct].each do |value|
        it "loads '#{value}' as #{value}" do
          type.load(value).should eq(value)
        end
      end
    end

    context 'when created using .of method' do
      let(:klass) { Integer }
      subject(:type) { Attributor::Class.of(klass) }

      it "loads 'Integer' as Integer" do
        type.load('Integer').should eq(Integer)
      end

      it 'returns specified class for nil' do
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
      expect { type.load(1) }.to raise_exception(Attributor::IncompatibleTypeError)
    end
  end
end
