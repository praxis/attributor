require_relative 'spec_helper'

describe Attributor::AttributeResolver do
  let(:value) { /\w+/.gen }

#  after do
#    # TODO: need to support this better in Skeletor somehow too.
#    Thread.current[:_attributor_attribute_resolver] = nil
#  end


  context 'registering and querying simple values' do
    let(:name) { "string_value" }
    before { subject.register(name,value) }

    it 'works' do
      subject.query(name).should be value
    end
  end


  context 'querying and registering nested values' do
    let(:one) { double(:two => value) }
    let(:key) { "one.two" }
    before { subject.register("one", one) }

    it 'works' do
      subject.query(key).should be value
    end
  end


  context 'querying nested values from models' do
    let(:instance) { double("instance", ssh_key:ssh_key) }
    let(:ssh_key) { double("ssh_key", name:value) }
    let(:key) { "instance.ssh_key.name" }

    before { subject.register('instance', instance) }

    it 'works' do
      subject.query("instance").should be instance
      subject.query("instance.ssh_key").should be ssh_key
      subject.query(key).should be value
    end


    context 'with a prefix' do
      let(:key) { "name" }
      let(:prefix) { "$.instance.ssh_key"}
      let(:value) { 'some_name' }
      it 'works' do
        subject.query(key,prefix).should be(value)
      end
    end

  end


  context 'querying values that do not exist' do
    context 'for a straight key' do
      let(:key) { "missing" }
      it 'returns nil' do
        subject.query(key).should be_nil
      end
    end
    context 'for a nested key' do
      let(:key) { "nested.missing" }
      it 'returns nil' do
        subject.query(key).should be_nil
      end
    end
  end


  context 'checking attribute conditions' do
    let(:key) { "instance.ssh_key.name" }
    let(:ssh_key) { double("ssh_key", name:value) }
    let(:instance) { double("instance", ssh_key:ssh_key) }

    let(:context) { '$' }

    before { subject.register('instance', instance) }

    let(:present_key) { key }
    let(:missing_key) { 'instance.ssh_key.something_else' }

    context 'with no condition' do
      let(:condition) { nil }
      before { ssh_key.should_receive(:something_else).and_return(nil) }
      it 'works' do
        subject.check(context, present_key, condition).should be true
        subject.check(context, missing_key, condition).should be false
      end
    end


    context 'with a string condition' do
      let(:passing_condition) { value }
      let(:failing_condition) { /\w+/.gen }

      it 'works' do
        subject.check(context, key, passing_condition).should be true
        subject.check(context, key, failing_condition).should be false
      end
    end


    context 'with a regex condition' do
      let(:passing_condition) { /\w+/ }
      let(:failing_condition) { /\d+/ }

      it 'works' do
        subject.check(context, key, passing_condition).should be true
        subject.check(context, key, failing_condition).should be false
      end

    end


    context 'with a hash condition' do
    end

    context 'with a proc condition' do
      let(:passing_condition) { Proc.new { |test_value| test_value == value } }
      let(:failing_condition) { Proc.new { |test_value| test_value != value } }

      it 'works' do
        subject.check(context, key, passing_condition).should be true
        subject.check(context, key, failing_condition).should be false
      end

    end

    context 'with an unsupported condition type' do
      let(:condition) { double("weird condition type") }
      it 'raises an error' do
        expect { subject.check(context, present_key, condition) }.to raise_error
      end
    end

    context 'with a condition that asserts something IS nil' do
      let(:ssh_key) { double("ssh_key", name: nil) }
      it 'can be done using the almighty Proc' do
        cond = Proc.new { |value| !value.nil? }
        subject.check(context, key, cond).should be false
      end
    end

    context 'with a relative path' do
      let(:context) { "$.instance.ssh_key"}
      let(:key) { "name" }

      it 'works' do
        subject.check(context, key, value).should be true
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
  #when you start to parse... do you set the root in the resolver?
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



