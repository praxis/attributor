require File.join(File.dirname(__FILE__), '../spec_helper.rb')


describe Attributor::Container do

  context '.decode_json' do
    let(:mock_type) do
      Class.new do
        include Attributor::Container
        def self.native_type
          ::Hash   
        end
      end
    end       
    context 'for valid JSON strings' do
      it "parses JSON string into the native type" do
        a_hash = {"a" => 1, "b" => 2}
        json_hash =  JSON.dump( a_hash )
        mock_type.decode_json(json_hash).should == a_hash
      end
      it 'complains when trying to decode a non-String value' do
        expect{ 
          mock_type.decode_json(Object.new)
        }.to raise_error(Attributor::DeserializationError, /Error deserializing a Object using JSON/)
      end
      
      it 'complains when the deserialized value is not of the native_type' do
        expect{ 
          mock_type.decode_json("[1,2,3]")
        }.to raise_error(Attributor::CoercionError, /Error coercing from Array/)
      end
      
      it 'complains if there is a error deserializing the string' do
        expect{ 
          mock_type.decode_json("{invalid_json}")
        }.to raise_error(Attributor::DeserializationError, /Error deserializing a String using JSON/)
      end
    end
  end
  
end