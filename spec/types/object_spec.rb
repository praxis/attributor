require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Object do
  context 'JSON Schema representation' do
    subject { UntypedObject.as_json_schema }
    it 'is an Any Type' do
      # "A schema without a type matches any data type – numbers, strings, objects, and so on."
      # c.f. https://swagger.io/docs/specification/data-models/data-types/#any
      expect(subject).not_to have_key(:type)
      # but we still preserve Ruby type name, if anyone is curious
      expect(subject[:"x-type_name"]).to eq("UntypedObject")
    end
  end
end
