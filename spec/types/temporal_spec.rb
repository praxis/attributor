require 'spec_helper'

describe Attributor::Temporal do
  subject(:type) do
    Class.new do
      include Attributor::Temporal
    end
  end

  it 'raises an exception for native_type' do
    expect { type.native_type }.to raise_error(NotImplementedError)
  end
end
