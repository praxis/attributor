require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Ids do

  context '.for' do
    let(:chickens) { 10.times.collect { Chicken.example } }

    let(:emails) { chickens.collect(&:email) }
    let(:value) { emails.join(',') }

    subject!(:ids) { Attributor::Ids.for(Chicken) }

    its(:member_attribute) { should be(Chicken.attributes[:email]) }


    it 'loads' do
      ids.load(value).should eq(emails)
    end

    it 'generates valid examples' do
      ids.validate(ids.example,nil,nil).should be_empty
    end

  end

end
