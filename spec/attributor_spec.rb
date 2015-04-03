require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Attributor do
  context '.resolve_type' do
    context 'given valid types' do
      {
        ::Integer => Attributor::Integer,
        Integer => Attributor::Integer,
        Attributor::Integer => Attributor::Integer,
        ::Attributor::Integer => Attributor::Integer,
        ::Attributor::DateTime => Attributor::DateTime,
        # FIXME: Boolean doesn't exist in Ruby, thus this causes and error
        # https://github.com/rightscale/attributor/issues/25
        #Boolean => Attributor::Boolean,
        Attributor::Boolean => Attributor::Boolean,
        Attributor::Struct => Attributor::Struct
      }.each do |type, expected_type|
        it "resolves #{type} as #{expected_type}" do
          Attributor.resolve_type(type).should == expected_type
        end
      end
    end
  end

  context '.humanize_context' do
    let(:context) { [] }

    subject(:humanized) { Attributor.humanize_context(context) }

    context 'with string value' do
      let(:context) { 'some-context'}
      it { should eq('some-context')}
    end

    context 'with array value' do
      let(:context) { ['a', 'b'] }
      it { should eq('a.b') }
    end

  end
end