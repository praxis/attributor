# frozen_string_literal: true

require 'spec_helper'

describe Attributor::Type do
  subject(:type) do
    Class.new { include Attributor::Type }
  end

  it 'raises an error for unimplemented example' do
    expect { type.example }.to raise_error(Attributor::AttributorException)
  end

  it 'raises an error for unimplemented valid_type?' do
    expect { type.valid_type?('foo') }.to raise_error(Attributor::AttributorException)
  end
end
