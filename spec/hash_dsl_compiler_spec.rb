require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::HashDSLCompiler do
  let(:target) { double('model', attributes: {}) }

  let(:dsl_compiler_options) { {} }
  subject(:dsl_compiler) { Attributor::HashDSLCompiler.new(target, **dsl_compiler_options) }

  it 'returns the requirements DSL attached to the right target' do
    req_dsl = dsl_compiler._requirements_dsl
    expect(req_dsl).to be_kind_of(Attributor::HashDSLCompiler::RequiresDSL)
    expect(req_dsl.target).to be(target)
  end

  context 'requires' do
    context 'without any arguments' do
      it 'without params returns the underlying compiler to chain internal methods' do
        expect(subject.requires).to be_kind_of(Attributor::HashDSLCompiler::RequiresDSL)
      end
    end

    context 'with params only (and some options)' do
      it 'takes then array to mean all attributes are required' do
        expect(target).to receive(:add_requirement)
        requirement = subject.requires :one, :two, description: 'These are very required'
        expect(requirement).to be_kind_of(Attributor::HashDSLCompiler::Requirement)
        expect(requirement.type).to be(:all)
      end
    end
    context 'with a block only (and some options)' do
      it 'evals it in the context of the Compiler' do
        proc = proc {}
        dsl = dsl_compiler._requirements_dsl
        expect(dsl).to receive(:instance_eval) # .with(&proc) << Does rspec 2.99 support block args?
        subject.requires description: 'These are very required', &proc
      end
    end
  end

  context 'RequiresDSL' do
    subject(:dsl) { Attributor::HashDSLCompiler::RequiresDSL.new(target) }
    it 'stores the received target' do
      expect(subject.target).to be(target)
    end

    context 'has DSL methods' do
      let(:req) { double('requirement') }
      let(:attr_names) { [:one, :two, :tree] }
      let(:number) { 2 }
      let(:req_class) { Attributor::HashDSLCompiler::Requirement }
      before do
        expect(target).to receive(:add_requirement).with(req)
      end
      it 'responds to .all' do
        expect(req_class).to receive(:new).with(all: attr_names).and_return(req)
        subject.all(*attr_names)
      end
      it 'responds to .at_most(n)' do
        expect(req_class).to receive(:new).with(at_most: number).and_return(req)
        subject.at_most(number)
      end
      it 'responds to .at_least(n)' do
        expect(req_class).to receive(:new).with(at_least: number).and_return(req)
        subject.at_least(number)
      end
      it 'responds to .exactly(n)' do
        expect(req_class).to receive(:new).with(exactly: number).and_return(req)
        subject.exactly(number)
      end
      it 'responds to .exclusive' do
        expect(req_class).to receive(:new).with(exclusive: attr_names).and_return(req)
        subject.exclusive(*attr_names)
      end
    end
  end

  context 'Requirement' do
    let(:attr_names) { [:one, :two, :tree] }
    let(:req_class) { Attributor::HashDSLCompiler::Requirement }

    context 'initialization' do
      it 'calls .of for exclusive' do
        expect_any_instance_of(req_class).to receive(:of).with(*attr_names)
        req_class.new(exclusive: attr_names)
      end
      it 'calls .of for all' do
        expect_any_instance_of(req_class).to receive(:of).with(*attr_names)
        req_class.new(all: attr_names)
      end
      it 'saves the number for the rest' do
        expect(req_class.new(exactly:  1).number).to be(1)
        expect(req_class.new(exactly:  1).type).to be(:exactly)
        expect(req_class.new(at_most:  2).number).to be(2)
        expect(req_class.new(at_most:  2).type).to be(:at_most)
        expect(req_class.new(at_least: 3).number).to be(3)
        expect(req_class.new(at_least: 3).type).to be(:at_least)
      end
      it 'understands and saves a :description' do
        req = req_class.new(exactly:  1, description: 'Hello')
        expect(req.number).to be(1)
        expect(req.description).to eq('Hello')
      end
    end

    context 'Requirement#validate' do
      let(:requirement) { req_class.new(**arguments) }
      let(:subject) { requirement.validate(value, ['$'], nil) }

      context 'for :all' do
        let(:arguments) { { all: [:one, :two, :three] } }
        let(:value) { [:one] }
        let(:validation_error) { ["Attribute $.key(:two) is required.", "Attribute $.key(:three) is required."] }
        it { expect(subject).to include(*validation_error) }
      end
      context 'for :exactly' do
        let(:requirement) { req_class.new(exactly: 1).of(:one, :two) }
        let(:value) { [:one, :two] }
        let(:validation_error) { 'Exactly 1 of the following attributes [:one, :two] are required for $. Found 2 instead: [:one, :two]' }
        it { expect(subject).to include(validation_error) }
      end
      context 'for :at_least' do
        let(:requirement) { req_class.new(at_least: 2).of(:one, :two, :three) }
        let(:value) { [:one] }
        let(:validation_error) { 'At least 2 attributes out of [:one, :two, :three] are required to be passed in for $. Found [:one]' }
        it { expect(subject).to include(validation_error) }
      end
      context 'for :at_most' do
        let(:requirement) { req_class.new(at_most: 1).of(:one, :two, :three) }
        let(:value) { [:one, :two] }
        let(:validation_error) { 'At most 1 attributes out of [:one, :two, :three] can be passed in for $. Found [:one, :two]' }
        it { expect(subject).to include(validation_error) }
      end
      context 'for :exclusive' do
        let(:arguments) { { exclusive: [:one, :two] } }
        let(:value) { [:one, :two] }
        let(:validation_error) { 'Attributes [:one, :two] are mutually exclusive for $.' }
        it { expect(subject).to include(validation_error) }
      end
    end

    context 'Requirement#describe' do
      it 'should work for :all' do
        req = req_class.new(all: attr_names).describe
        expect(req).to eq(type: :all, attributes: [:one, :two, :tree])
      end
      it 'should work for :exclusive n' do
        req = req_class.new(exclusive: attr_names).describe
        expect(req).to eq(type: :exclusive, attributes: [:one, :two, :tree])
      end
      it 'should work for :exactly' do
        req = req_class.new(exactly: 1).of(*attr_names).describe
        expect(req).to include(type: :exactly, count: 1, attributes: [:one, :two, :tree])
      end
      it 'should work for :at_most n' do
        req = req_class.new(at_most: 1).of(*attr_names).describe
        expect(req).to include(type: :at_most, count: 1, attributes: [:one, :two, :tree])
      end
      it 'should work for :at_least n' do
        req = req_class.new(at_least: 1).of(*attr_names).describe
        expect(req).to include(type: :at_least, count: 1, attributes: [:one, :two, :tree])
      end
      it 'should report a description' do
        req = req_class.new(at_least: 1, description: 'no more than 1').of(*attr_names).describe
        expect(req).to include(type: :at_least, count: 1, attributes: [:one, :two, :tree], description: 'no more than 1')
      end
    end
  end
end
