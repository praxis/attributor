require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe 'Type families' do

  let(:types) { ObjectSpace.each_object(Class).select { |k| k < Attributor::Type } }

  it 'are set on all types' do
    types.each do |type|
      next if type == Attributor::Object # object has no set family
      type.should_not be_in_family('attributor')
    end
  end

end
