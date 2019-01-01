# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::SmartAttributeSelector do
  let(:type) { Attributor::Hash.construct(block) }
  let(:block) do
    proc do
      key :req1, String
      key :req2, String
      key :exc3, String
      key :exc4, String
      key :least1, String
      key :least2, String
      key :exact1, String
      key :exact2, String
      key :most1, String
      key :most2, String

      requires.all :req1, :req2
      requires.exclusive :exc3, :exc4
      requires.at_least(2).of :least1, :least2
      requires.exactly(1).of :exc3, :exact1, :exact2
      requires.at_most(1).of :most1, :most2
      requires.at_least(1).of :exc4, :exc3
    end
  end

  let(:reqs) { type.requirements.map(&:describe) }
  let(:attributes) { [] }
  let(:values) { {} }
  let(:remaining_attrs) { [] }

  subject(:selector) { Attributor::SmartAttributeSelector.new(reqs, attributes, values) }
  let(:accepted_attrs) { [] }

  after do
    expect(subject.accepted).to contain_exactly(*accepted_attrs)
    expect(subject.remaining).to contain_exactly(*remaining_attrs)
  end

  context 'process' do
    let(:accepted_attrs) { %i[req1 req2 exc3 least1 least2 most1] }
    it 'aggregates results from the different requirements' do
      expect(subject).to receive(:process_required).once.and_call_original
      expect(subject).to receive(:process_exclusive).once.and_call_original
      expect(subject).to receive(:process_at_least).once.and_call_original
      expect(subject).to receive(:process_exactly).once.and_call_original
      expect(subject).to receive(:process_at_most).once.and_call_original
      subject.process
    end
  end

  context 'process_required' do
    context 'processing only required attrs' do
      let(:block) do
        proc do
          key :req1, String
          key :req2, String
          requires.all :req1, :req2
        end
      end
      let(:accepted_attrs) { %i[req1 req2] }
      it 'processes required' do
        subject.process_required
      end
    end

    context 'processing some required attrs, others attrs without reqs' do
      let(:block) do
        proc do
          key :req1, String
          key :req2, String
          requires.all :req1
        end
      end
      let(:accepted_attrs) { [:req1] }

      it 'processes required' do
        subject.process_required
      end
    end
  end

  context 'process_exclusive' do
    context 'uses exclusive,at_most(1) and exactly(1)' do
      let(:block) do
        proc do
          key :req1, String
          key :req2, String
          key :req3, String
          key :req4, String
          key :req5, String
          key :req6, String

          requires.exclusive :req1, :req2
          requires.at_most(1).of :req3, :req4
          requires.exactly(1).of :req5, :req6
        end
      end
      let(:accepted_attrs) { %i[req1 req3 req5] }
      it 'processes required' do
        expect(subject).to receive(:process_exclusive_set).with(%i[req1 req2]).and_call_original
        expect(subject).to receive(:process_exclusive_set).with(%i[req3 req4]).and_call_original
        expect(subject).to receive(:process_exclusive_set).with(%i[req5 req6]).and_call_original

        subject.process_exclusive
      end
    end
  end

  context 'internal functions' do
    context 'process_exclusive_set' do
      context 'picks the first of the set bans the rest' do
        let(:set) { %i[req1 req2] }
        let(:accepted_attrs) { [:req1] }

        it 'processes required' do
          subject.process_exclusive_set(set)
          expect(subject.banned).to eq([:req2])
        end
      end

      context 'picks the first not banned, and bans the rest' do
        let(:set) { %i[req2 req3] }
        let(:accepted_attrs) { [:req3] }

        it 'processes required' do
          subject.banned = [:req2] # Explicitly ban one
          subject.process_exclusive_set(set)
          expect(subject.banned).to eq([:req2])
        end
      end

      context 'finds it unfeasible' do
        let(:set) { %i[req2 req3] }

        it 'processes required' do
          subject.banned = %i[req2 req3] # Ban them all
          expect do
            subject.process_exclusive_set(set)
          end.to raise_error(Attributor::UnfeasibleRequirementsError)
        end
        it 'unless the set was empty to begin with' do
          expect do
            subject.process_exclusive_set([])
          end.to_not raise_error
        end
      end

      context 'favors attributes with values' do
        let(:values) { { req2: 'foo' } }
        let(:set) { %i[req1 req2] }
        let(:accepted_attrs) { [:req2] }

        it 'processes required' do
          subject.process_exclusive_set(set)
          expect(subject.banned).to eq([:req1])
        end
      end

      context 'manages the remaining set' do
        let(:attributes) { %i[req1 req2 req3] }
        let(:set) { %i[req1 req2] }
        let(:accepted_attrs) { [:req1] }
        let(:remaining_attrs) { [:req3] }

        it 'processes required' do
          subject.process_exclusive_set(set)
          expect(subject.banned).to eq([:req2])
        end
      end
    end

    context 'process_at_least_set' do
      context 'picks the count in order' do
        let(:set) { %i[req1 req2 req3] }
        let(:accepted_attrs) { %i[req1 req2] }

        it 'processes required' do
          subject.process_at_least_set(set, 2)
        end
      end

      context 'picks the count in order, skipping banned' do
        let(:set) { %i[req1 req2 req3] }
        let(:accepted_attrs) { %i[req1 req3] }

        it 'processes required' do
          subject.banned = [:req2] # Explicitly ban one
          subject.process_at_least_set(set, 2)
        end
      end

      context 'finds it unfeasible' do
        let(:set) { %i[req1 req2 req3] }

        it 'processes required' do
          expect do
            subject.process_at_least_set(set, 4)
          end.to raise_error(Attributor::UnfeasibleRequirementsError)
        end
      end

      context 'favors attributes with values' do
        let(:values) { { req1: 'foo', req3: 'bar' } }
        let(:set) { %i[req1 req2 req3] }
        let(:accepted_attrs) { %i[req1 req3] }

        it 'processes required' do
          subject.process_at_least_set(set, 2)
        end
      end
    end

    context 'process_at_most_set' do
      context 'picks half the max count in attr order' do
        let(:set) { %i[req1 req2 req3 req4 req5] }
        let(:accepted_attrs) { %i[req1 req2] }

        it 'processes required' do
          subject.process_at_most_set(set, 4)
        end
      end
      context 'favors attributes with values (and refills with others)' do
        let(:values) { { req3: 'foo', req5: 'bar' } }
        let(:set) { %i[req1 req2 req3 req4 req5] }
        let(:accepted_attrs) { %i[req3 req5 req1] }

        it 'processes required' do
          subject.process_at_most_set(set, 5)
        end
      end
    end

    context 'process_exactly_set' do
      context 'picks exact count in attr order' do
        let(:set) { %i[req1 req2 req3 req4 req5] }
        let(:accepted_attrs) { %i[req1 req2] }

        it 'processes required' do
          subject.process_exactly_set(set, 2)
        end
      end
      context 'favors attributes with values (and refills with others)' do
        let(:values) { { req3: 'foo' } }
        let(:set) { %i[req1 req2 req3 req4 req5] }
        let(:accepted_attrs) { %i[req3 req1] }

        it 'processes required' do
          subject.process_exactly_set(set, 2)
        end
      end

      context 'finds it unfeasible' do
        let(:set) { %i[req1 req2] }

        it 'processes required' do
          subject.banned = [:req2] # Explicitly ban one
          expect do
            subject.process_exactly_set(set, 2)
          end.to raise_error(Attributor::UnfeasibleRequirementsError)
        end
      end
    end
  end
end
