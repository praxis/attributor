require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Model do

  context 'class methods' do
    subject(:chicken) { Chicken }

    its(:native_type) { should eq(Chicken) }

    context '.example'  do
      subject(:example) { Chicken.example }

      let(:age_opts) { chicken.definition.attributes['age'].options }
      let(:age) { /\d{2}/.gen.to_i }

      before do
        Attributor::Integer.should_receive(:example).with(/age$/, age_opts).and_return(age)
        Attributor::String.should_not_receive(:example) # due to the :example option on the attribute
      end

      it { should be_kind_of(Chicken) }

      its(:age) { should == age }
      its(:email) { should =~ /\w+@.*\.example\.org/ }
    end


    context '.definition' do
      subject(:definition) { Chicken.definition }

      context '#attributes' do
        subject(:attributes) { definition.attributes }
        it { should have_key "age" }
        it { should have_key "email" }
      end
    end


    context '.load' do
      let(:age) { 1 }
      let(:email) { "cluck@example.org" }
      let(:hash) { {"age"=>age, "email"=>email} }

      subject(:model) { Chicken.load(hash) }

      context 'with an instance of the model' do
        it 'returns the instance' do
          Chicken.load(model).should be(model)
        end
      end

      context 'with a nil value' do
        it 'returns nil' do
          Chicken.load(nil).should be_nil
        end
      end

      context 'with a JSON-serialized hash' do
        let(:json) { hash.to_json }
        before do
          Chicken.should_receive(:from_hash).
            with(hash)
          JSON.should_receive(:parse).with(json).and_call_original
        end

        it 'deserializes and calls from_hash' do
          Chicken.load(json)
        end
      end

      context 'with an invalid object type' do
        it 'raises some sort of error' do
          expect {
            Chicken.load(Object.new)
          }.to raise_error(/Can not load Chicken from value .* of type Object/)
        end
      end

      context "with a hash" do
        context 'for a complete set of attributes' do
          it 'loads the given attributes' do
            model.age.should == age
            model.email.should == email
          end
        end

        context 'for a subset of attributes' do
          let(:hash) { Hash.new }

          it 'sets the defaults' do
            model.age.should == 1
            model.email.should == nil
          end
        end

        context 'for a superset of attributes' do
          let(:hash) { {"invalid_attribute" => "value"} }

          it 'raises an error' do
            expect {
              Chicken.load(hash)
            }.to raise_error(Attributor::AttributorException, /Unknown attributes/)
          end
        end
      end


    end

  end


  context 'instance methods' do
    subject(:chicken) { Chicken.new }

    context '#respond_to?' do
      [:age, :email, :age=, :email=].each do |method|
        it { should respond_to(method) }
      end
    end

    context 'getting and setting attributes' do
      context 'for valid attributes' do
        let(:age) { 1 }
        it 'gets and sets attributes' do
          chicken.age = age
          chicken.age.should == age
        end
      end

      context 'setting nil' do
        it 'assigns the default value if there is one' do
          chicken.age = nil
          chicken.age.should == 1
        end

        it 'sets the value to nil if there is no default' do
          chicken.email = nil
          chicken.email.should == nil
        end

      end

      context 'for unknown attributes' do
        it 'raises an exception' do
          expect {
            chicken.invalid_attribute =  'value'
          }.to raise_error(NoMethodError, /undefined method/)
        end
      end

    end

  end

end
