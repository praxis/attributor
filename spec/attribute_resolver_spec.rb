require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::AttributeResolver do
  let(:value) { /\w+/.gen }

  context 'registering and querying simple values' do
    let(:name) { 'string_value' }
    before { subject.register(name, value) }

    it 'works' do
      expect(subject.query(name)).to be value
    end
  end

  context 'querying and registering nested values' do
    let(:one) { double(two: value) }
    let(:key) { 'one.two' }
    before { subject.register('one', one) }

    it 'works' do
      expect(subject.query(key)).to be value
    end
  end

  context 'querying nested values from models' do
    let(:instance) { double('instance', ssh_key: ssh_key) }
    let(:ssh_key) { double('ssh_key', name: value) }
    let(:key) { 'instance.ssh_key.name' }

    before { subject.register('instance', instance) }

    it 'works' do
      expect(subject.query('instance')).to be instance
      expect(subject.query('instance.ssh_key')).to be ssh_key
      expect(subject.query(key)).to be value
    end

    context 'with a prefix' do
      let(:key) { 'name' }
      let(:prefix) { '$.instance.ssh_key' }
      let(:value) { 'some_name' }
      it 'works' do
        expect(subject.query(key, prefix)).to be(value)
      end
    end
  end

  context 'querying values that do not exist' do
    context 'for a straight key' do
      let(:key) { 'missing' }
      it 'returns nil' do
        expect(subject.query(key)).to be_nil
      end
    end
    context 'for a nested key' do
      let(:key) { 'nested.missing' }
      it 'returns nil' do
        expect(subject.query(key)).to be_nil
      end
    end
  end

  context 'querying collection indices from models' do
    let(:instances) { [instance1, instance2] }
    let(:instance1) { double('instance1', ssh_key: ssh_key1) }
    let(:instance2) { double('instance2', ssh_key: ssh_key2) }
    let(:ssh_key1) { double('ssh_key', name: value) }
    let(:ssh_key2) { double('ssh_key', name: 'second') }
    let(:args) { [path, prefix].compact }

    before { subject.register('instances', instances) }

    it 'resolves the index to the correct member of the collection' do
      expect(subject.query('instances')).to be instances
      expect(subject.query('instances.at(1).ssh_key')).to be ssh_key2
      expect(subject.query('instances.at(0).ssh_key.name')).to be value
    end

    it 'returns nil for index out of range' do
      expect(subject.query('instances.at(2)')).to be(nil)
      expect(subject.query('instances.at(-1)')).to be(nil)
    end

    context 'with a prefix' do
      let(:key) { 'name' }
      let(:prefix) { '$.instances.at(0).ssh_key' }
      let(:value) { 'some_name' }

      it 'resolves the index to the correct member of the collection' do
        expect(subject.query(key, prefix)).to be(value)
      end
    end
  end

  context 'checking attribute conditions' do
    let(:key) { 'instance.ssh_key.name' }
    let(:ssh_key) { double('ssh_key', name: value) }
    let(:instance_id) { 123 }
    let(:instance) { double('instance', ssh_key: ssh_key, id: instance_id) }

    let(:context) { '$' }

    before { subject.register('instance', instance) }

    let(:present_key) { key }
    let(:missing_key) { 'instance.ssh_key.something_else' }

    context 'with no condition' do
      let(:condition) { nil }
      before { expect(ssh_key).to receive(:something_else).and_return(nil) }
      it 'works' do
        expect(subject.check(context, present_key, condition)).to be true
        expect(subject.check(context, missing_key, condition)).to be false
      end
    end

    context 'with a string condition' do
      let(:passing_condition) { value }
      let(:failing_condition) { /\w+/.gen }

      it 'works' do
        expect(subject.check(context, key, passing_condition)).to be true
        expect(subject.check(context, key, failing_condition)).to be false
      end
    end

    context 'with a regex condition' do
      let(:passing_condition) { /\w+/ }
      let(:failing_condition) { /\d+/ }

      it 'works' do
        expect(subject.check(context, key, passing_condition)).to be true
        expect(subject.check(context, key, failing_condition)).to be false
      end
    end

    context 'with an integer condition' do
      let(:key) { 'instance.id' }
      let(:passing_condition) { instance_id }
      let(:failing_condition) { /\w+/.gen }

      it 'works' do
        expect(subject.check(context, key, passing_condition)).to be true
        expect(subject.check(context, key, failing_condition)).to be false
      end
    end

    skip 'with a hash condition' do
    end

    context 'with a proc condition' do
      let(:passing_condition) { proc { |test_value| test_value == value } }
      let(:failing_condition) { proc { |test_value| test_value != value } }

      it 'works' do
        expect(subject.check(context, key, passing_condition)).to eq(true)
        expect(subject.check(context, key, failing_condition)).to eq(false)
      end
    end

    context 'with an unsupported condition type' do
      let(:condition) { double('weird condition type') }
      it 'raises an error' do
        expect { subject.check(context, present_key, condition) }.to raise_error(Attributor::AttributorException)
      end
    end

    context 'with a condition that asserts something IS nil' do
      let(:ssh_key) { double('ssh_key', name: nil) }
      it 'can be done using the almighty Proc' do
        cond = proc { |value| !value.nil? }
        expect(subject.check(context, key, cond)).to be false
      end
    end

    context 'with a relative path' do
      let(:context) { '$.instance.ssh_key' }
      let(:key) { 'name' }

      it 'works' do
        expect(subject.check(context, key, value)).to be true
      end
    end
  end

  # context 'with context stuff...' do

  #   let(:ssh_key) { double("ssh_key", name:value) }
  #   let(:instance) { double("instance", ssh_key:ssh_key) }

  #   let(:key) { "ssh_key.name" }
  #   let(:key) { "$.payload" }
  #   let(:key) { "ssh_key.name" } # no $ == current object
  #   let(:key) { "@.ssh_key" }    # @ is current object

  #   before { subject.register('instance', instance) }

  #   it 'works?' do
  #     # check dependency for 'instance'
  #     resolver.with 'instance' do |res|
  #       res.check(key)
  #       '$.payload'
  #     end

  #   end

  # end

  # context 'integration with attributes that have sub-attributes' do
  # when you start to parse... do you set the root in the resolver?
  # end
  #
  #  context 'actually using the thing' do

  #   # we'll always want to add... right? never really remove?
  #   # at least not remove for the duration of a given resolver...
  #   # which will last for one request.
  #   #
  #   # could the resolver be an identity-map of sorts for the request?
  #   # how much overlap is there in there?
  #   #
  #   #

  #   it 'is really actually quite useful' do
  #     #attribute = Attributor::Attribute.new ::String, required_if: { "instance.ssh_key.name" : Proc.new { |value| value.nil? } }

  #     resolver = Attributor::AttributeResolver.new

  #     resolver.register '$.parsed_params', parsed_params
  #     resolver.register '$.payload', payload

  #     resolver.query '$.parsed_params.account_id'

  #   end

  # end
end
