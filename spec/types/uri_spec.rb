describe Attributor::URI do

  subject(:type) { Attributor::URI }

  its(:native_type) { should be ::URI::Generic }

  it 'check_option!' do
    # No options supported thus far
    expect(type.check_option!(:foo, nil )).to be(:unknown)
  end

end
