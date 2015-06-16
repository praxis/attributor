require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Ids do

  context '.for' do
    let(:chickens) { 10.times.collect { Chicken.example } }

    let(:emails) { chickens.collect(&:email) }
    let(:value) { emails.join(',') }

    subject!(:ids) { Attributor::Ids.for(Chicken) }

    its(:member_attribute) { should be(Chicken.attributes[:email]) }

    it 'loads' do
      ids.load(value).should =~ emails
    end

    it 'generates valid, loadable examples' do
      ids.validate(ids.load(ids.example)).should be_empty
    end

  end

  context 'attempting to define it as a collection using .of(type)' do
    it 'raises an error' do
      expect{
        Attributor::Ids.of(Chicken)
      }.to raise_error(/Defining Ids.of\(type\) is not allowed/)
    end
  end
end
