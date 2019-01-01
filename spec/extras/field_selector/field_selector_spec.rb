# frozen_string_literal: true

require 'spec_helper'
require 'attributor/extras/field_selector'

describe Attributor::FieldSelector do
  subject(:type) { Attributor::FieldSelector }

  it 'loads a Hash' do
    expect(subject.load('one,two')).to be_kind_of(::Hash)
  end

  context 'loading all the test combinations' do
    cases = {
      nil => nil,
      '' => {},
      'one' => { one: true },
      'one,two,three' => { one: true, two: true, three: true },
      'one,two{a,b},three' => { one: true, two: { a: true, b: true }, three: true },
      'one,two{a,b,c{A,B}},three' => {
        one: true,
        two: {
          a: true,
          b: true,
          c: { A: true, B: true }
        },
        three: true
      }
    }

    cases.each do |fields, result|
      it "loads #{fields.inspect}" do
        loaded = subject.load(fields)
        expect(loaded).to eq result
      end
    end
  end
end
