require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Attributor do
  context '.compare_versions' do
    it 'correctly compares two versions' do
      Attributor.compare_versions('1.9.3', '<', '1.10.0').should eq(true)
      Attributor.compare_versions('1.9.3', '>', '1.10.0').should eq(false)
      Attributor.compare_versions('1.9.3', '>=', '1.10.0').should eq(false)
      Attributor.compare_versions('1.9.3', '<=', '1.10.0').should eq(true)
      Attributor.compare_versions('1.9.3', '==', '1.10.0').should eq(false)
    end
  end

  context '.check_version' do
    it 'correctly applies constraint to current Ruby version' do
      less_than_ruby_19 = Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('1.9')
      Attributor.check_ruby_version('<', '1.9').should == less_than_ruby_19
    end
  end

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
end