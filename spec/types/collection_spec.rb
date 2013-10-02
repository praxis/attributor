require_relative '../spec_helper'

describe Attributor::Collection do

  subject(:type) { Attributor::Collection }

  context '.native_type' do
    it "should return Array" do
      type.native_type.should be(::Array)
    end
  end
end

