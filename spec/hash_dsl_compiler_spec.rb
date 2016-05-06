require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::HashDSLCompiler do
  let(:target) { double('model', attributes: {}) }

  let(:dsl_compiler_options) { {} }
  subject(:dsl_compiler) { Attributor::HashDSLCompiler.new(target, dsl_compiler_options) }

  it 'returns the requirements DSL attached to the right target' do
    req_dsl = dsl_compiler._requirements_dsl
    req_dsl.should be_kind_of(Attributor::HashDSLCompiler::RequiresDSL)
    req_dsl.target.should be(target)
  end

  context 'requires' do
    context 'without any arguments' do
      it 'without params returns the underlying compiler to chain internal methods' do
        subject.requires.should be_kind_of(Attributor::HashDSLCompiler::RequiresDSL)
      end
    end

    context 'with params only (and some options)' do
      it 'takes then array to mean all attributes are required' do
        target.should_receive(:add_requirement)
        requirement = subject.requires :one, :two, description: 'These are very required'
        requirement.should be_kind_of(Attributor::HashDSLCompiler::Requirement)
        requirement.type.should be(:all)
      end
    end
    context 'with a block only (and some options)' do
      it 'evals it in the context of the Compiler' do
        proc = proc {}
        dsl = dsl_compiler._requirements_dsl
        dsl.should_receive(:instance_eval) # .with(&proc) << Does rspec 2.99 support block args?
        subject.requires description: 'These are very required', &proc
      end
    end
  end

  context 'RequiresDSL' do
    subject(:dsl) { Attributor::HashDSLCompiler::RequiresDSL.new(target) }
    it 'stores the received target' do
      subject.target.should be(target)
    end

    context 'has DSL methods' do
      let(:req) { double('requirement') }
      let(:attr_names) { [:one, :two, :tree] }
      let(:number) { 2 }
      let(:req_class) { Attributor::HashDSLCompiler::Requirement }
      before do
        target.should_receive(:add_requirement).with(req)
      end
      it 'responds to .all' do
        req_class.should_receive(:new).with(all: attr_names).and_return(req)
        subject.all(*attr_names)
      end
      it 'responds to .at_most(n)' do
        req_class.should_receive(:new).with(at_most: number).and_return(req)
        subject.at_most(number)
      end
      it 'responds to .at_least(n)' do
        req_class.should_receive(:new).with(at_least: number).and_return(req)
        subject.at_least(number)
      end
      it 'responds to .exactly(n)' do
        req_class.should_receive(:new).with(exactly: number).and_return(req)
        subject.exactly(number)
      end
      it 'responds to .exclusive' do
        req_class.should_receive(:new).with(exclusive: attr_names).and_return(req)
        subject.exclusive(*attr_names)
      end
    end
  end

  context 'Requirement' do
    let(:attr_names) { [:one, :two, :tree] }
    let(:req_class) { Attributor::HashDSLCompiler::Requirement }

    context 'initialization' do
      it 'calls .of for exclusive' do
        req_class.any_instance.should_receive(:of).with(*attr_names)
        req_class.new(exclusive: attr_names)
      end
      it 'calls .of for all' do
        req_class.any_instance.should_receive(:of).with(*attr_names)
        req_class.new(all: attr_names)
      end
      it 'saves the number for the rest' do
        req_class.new(exactly:  1).number.should be(1)
        req_class.new(exactly:  1).type.should be(:exactly)
        req_class.new(at_most:  2).number.should be(2)
        req_class.new(at_most:  2).type.should be(:at_most)
        req_class.new(at_least: 3).number.should be(3)
        req_class.new(at_least: 3).type.should be(:at_least)
      end
      it 'understands and saves a :description' do
        req = req_class.new(exactly:  1, description: 'Hello')
        req.number.should be(1)
        req.description.should eq('Hello')
      end
    end

    context 'Requirement#validate' do
      let(:requirement) { req_class.new(arguments) }
      let(:subject) { requirement.validate(value, ['$'], nil) }

      context 'for :all' do
        let(:arguments) { { all: [:one, :two, :three] } }
        let(:value) { { one: 1 } }
        let(:validation_error) { ['Key two is required for $.', 'Key three is required for $.'] }
        it { subject.should include(*validation_error) }
      end
      context 'for :exactly' do
        let(:requirement) { req_class.new(exactly: 1).of(:one, :two) }
        let(:value) { { one: 1, two: 2 } }
        let(:validation_error) { 'Exactly 1 of the following keys [:one, :two] are required for $. Found 2 instead: [:one, :two]' }
        it { subject.should include(validation_error) }
      end
      context 'for :at_least' do
        let(:requirement) { req_class.new(at_least: 2).of(:one, :two, :three) }
        let(:value) { { one: 1 } }
        let(:validation_error) { 'At least 2 keys out of [:one, :two, :three] are required to be passed in for $. Found [:one]' }
        it { subject.should include(validation_error) }
      end
      context 'for :at_most' do
        let(:requirement) { req_class.new(at_most: 1).of(:one, :two, :three) }
        let(:value) { { one: 1, two: 2 } }
        let(:validation_error) { 'At most 1 keys out of [:one, :two, :three] can be passed in for $. Found [:one, :two]' }
        it { subject.should include(validation_error) }
      end
      context 'for :exclusive' do
        let(:arguments) { { exclusive: [:one, :two] } }
        let(:value) { { one: 1, two: 2 } }
        let(:validation_error) { 'keys [:one, :two] are mutually exclusive for $.' }
        it { subject.should include(validation_error) }
      end
    end

    context 'Requirement#describe' do
      it 'should work for :all' do
        req = req_class.new(all: attr_names).describe
        req.should eq(type: :all, attributes: [:one, :two, :tree])
      end
      it 'should work for :exclusive n' do
        req = req_class.new(exclusive: attr_names).describe
        req.should eq(type: :exclusive, attributes: [:one, :two, :tree])
      end
      it 'should work for :exactly' do
        req = req_class.new(exactly: 1).of(*attr_names).describe
        req.should include(type: :exactly, count: 1, attributes: [:one, :two, :tree])
      end
      it 'should work for :at_most n' do
        req = req_class.new(at_most: 1).of(*attr_names).describe
        req.should include(type: :at_most, count: 1, attributes: [:one, :two, :tree])
      end
      it 'should work for :at_least n' do
        req = req_class.new(at_least: 1).of(*attr_names).describe
        req.should include(type: :at_least, count: 1, attributes: [:one, :two, :tree])
      end
      it 'should report a description' do
        req = req_class.new(at_least: 1, description: 'no more than 1').of(*attr_names).describe
        req.should include(type: :at_least, count: 1, attributes: [:one, :two, :tree], description: 'no more than 1')
      end
    end
  end
end
