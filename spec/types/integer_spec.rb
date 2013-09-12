require_relative '../spec_helper'

describe Attributor::Integer do

  subject(:type) { Attributor::Integer }
  context '.load' do
    let(:value) { nil }


    context 'for incoming integer values' do
      let(:value) { 1 }

      it 'returns the incoming value' do
        type.load(value).should be(value)
      end
    end

    context 'for incoming string values' do


      context 'that are valid integers' do
        let(:value) { '1024' }
        it 'decodes it if the string represents an integer' do
          type.load(value).should == 1024
        end
      end

      context 'that are not valid integers' do

        context 'with simple alphanumeric text' do
          let(:value) { 'not an integer' }
        end

        context 'with a floating point value' do
          let(:value) { '98.76' }
        end

      end


      #       it 'contains simple alphanumeric text' do
      #         val="not an integer"
      #         object, errors = subject.decode(val,'context')
      #         errors.first.should =~ /Could not decode an integer from this String./
      #         object.should be_nil
      #       end
      #       it 'contains a floating point value' do
      #         val="98.76"
      #         object, errors = subject.decode(val,'context')
      #         errors.first.should =~ /Could not decode an integer from this String./
      #         object.should be_nil
      #       end
      #     end
      #   end

      #   context 'for incoming values of non-supported types' do
      #     it 'always returns errors complaining about the unknown type' do
      #       val={'this'=>'is', 'a'=>'hash' }
      #       object, errors = subject.decode(val,'context')
      #       errors.first.should =~ /Do not know how to load an integer from/
      #       object.should be_nil
      #     end
      #   end
      # end

    end
  end
end

