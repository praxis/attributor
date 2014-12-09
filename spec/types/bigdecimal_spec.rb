require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::BigDecimal do
  subject(:type) { Attributor::BigDecimal }

  context '.native_type' do
    its(:native_type) { should be(::BigDecimal) }
  end

  context '.example' do
    its(:example) { should be_a(::BigDecimal) }
    it do 
      ex = type.example
    end
  end

  context '.load' do
    let(:value) { nil }
    it 'returns nil for nil' do
      type.load(nil).should be(nil)
    end
    
    #context 'for incoming Float values' do
    #  it 'returns the incoming value' do
    #    [0.0, -1.0, 1.0, 1e-10].each do |value|
    #      type.load(value).should be(value)
    #    end
    #  end
    #end

    context 'for incoming Integer values' do
      it 'should equal the incoming value' do
        [0, -1, 1].each do |value|
          type.load(value).should eq(value)
        end
      end
    end

    context 'for incoming String values' do 
      it 'should equal the value' do
        type.load('0').should eq(0)
        type.load('100').should eq(100)
        type.load('0.1').should eq(0.1)
      end
    end

  end
end



            

#             context 'for incoming Integer values' do

#                   context 'with an integer value' do
#                         let(:value) { 1 }
#                         it 'decodes it if the Integer represents a Float' do
#                               type.load(value).should == 1.0
#                         end
#                   end
#             end

#             context 'for incoming String values' do

#                   context 'that are valid Floats' do
#                         ['0.0', '-1.0', '1.0', '1e-10'].each do |value|
#                               it 'decodes it if the String represents a Float' do
#                                     type.load(value).should == Float(value)
#                               end
#                         end
#                   end

#                   #   context 'that are valid Integers' do
#                   #     let(:value) { '1' }
#                   #     it 'decodes it if the String represents an Integer' do
#                   #       type.load(value).should == 1.0
#                   #     end
#                   #   end

#                   #   context 'that are not valid Floats' do

#                   #     context 'with simple alphanumeric text' do
#                   #       let(:value) { 'not a Float' }

#                   #       it 'raises an error' do
#                   #         expect { type.load(value) }.to raise_error(/invalid value/)
#                   #       end
#                   #     end

#                   #   end
#             end
#       end
# end
