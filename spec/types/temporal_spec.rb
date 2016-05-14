require 'spec_helper'

describe Attributor::Temporal do
  subject(:type) { Attributor::Temporal }

  it 'raises an exception for native_type' do
    expect { type.native_type }.to raise_error(NotImplementedError)
  end
end
