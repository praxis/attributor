require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Attributor::DSLCompiler do


  let(:dsl_compiler_options) { {} }
  subject(:dsl_compiler) { Attributor::DSLCompiler.new(dsl_compiler_options) }

  let(:attribute_name) { "name" }
  let(:type) { Attributor::String }

  let!(:reference_attributes) { Turducken.definition.attributes }
  let(:reference_type) { reference_attribute.type }
  let(:reference_attribute_options) { reference_attribute.options }
  let(:reference_attribute) {reference_attributes[attribute_name] }

  context '#parse_arguments' do

    let(:type_or_options) { nil }
    let(:opts) { nil }

    subject(:parsed_arguments) { dsl_compiler.parse_arguments(type_or_options, opts) }

    context 'with nil and nil' do
      its(:first) { should == nil } # type
      its(:last)  { should == {}  } # opts
    end

    context 'with nil and {}' do
      let(:opts) { Hash.new }

      its(:first) { should == nil }   # type
      its(:last)  { should be(opts) } # opts
    end

    context 'with hash and nil' do
      let(:type_or_options) { Hash.new }

      its(:first) { should == nil }              # type
      its(:last)  { should be(type_or_options) } # opts
    end

    context 'with a class and hash' do
      let(:type_or_options) { ::Object }
      let(:opts) { Hash.new }

      its(:first) { should == type_or_options } # type
      its(:last)  { should be(opts)  }          # opts
    end

    context 'with a class and nil' do
      let(:type_or_options) { ::Object }

      its(:first) { should == type_or_options } # type
      its(:last)  { should == {} }              # opts
    end

  end


  context '#attribute' do
    let(:attribute_options) { {} }

    let(:expected_options) { attribute_options }
    let(:expected_type) { type }

    it 'has a spec for non-string names blowing'

    context 'when not not given a block for a sub-definition' do


      context 'without a reference' do

        it 'raises an error for a missing type' do
          expect {
            dsl_compiler.attribute(attribute_name)
          }.to raise_error(/type for attribute/)

        end

        it 'creates an attribute given a name and type' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, type)
        end


        it 'creates an attribute given a name, type, and options' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, type, attribute_options)
        end

      end


      context 'with a reference' do
        let(:dsl_compiler_options) { {:reference => Turducken} }

        context 'with no options' do
          let(:expected_options) { reference_attribute_options }

          it 'creates an attribute with the inherited type' do
            Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
            dsl_compiler.attribute(attribute_name)
          end
        end

        context 'with options' do
          let(:attribute_options) { {:description => "some new description", :required => true} }
          let(:expected_options) { reference_attribute_options.merge(attribute_options) }

          before do
            Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          end

          it 'creates an attribute with the inherited type and merged options' do
            dsl_compiler.attribute(attribute_name, attribute_options)
          end

          it 'accepts explicit nil type' do
            dsl_compiler.attribute(attribute_name, nil, attribute_options)
          end

        end

        context 'for a referenced Model attribute' do
          let(:attribute_name) { "turkey" }
          let(:expected_type) { Turkey }
          let(:expected_options) { reference_attribute_options.merge(attribute_options) }

          it 'creates an attribute with the inherited type' do
            Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
            dsl_compiler.attribute(attribute_name)
          end
        end

      end

    end


    context 'when given a block for sub-attributes' do
      let(:attribute_block) { Proc.new { } }
      let(:attribute_name) { "turkey" }
      let(:type) { Attributor::Struct }
      let(:expected_type) { Attributor::Struct }

      context 'without a reference' do
        it 'defaults type to Struct' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, &attribute_block)
        end
      end

      context 'with a reference' do
        let(:dsl_compiler_options) { {:reference => Turducken} }
        let(:expected_options) do
          attribute_options.merge(:reference => reference_type)
        end

        it 'is unhappy from somewhere else if you do not specify a type' do
          expect {
            dsl_compiler.attribute(attribute_name, attribute_options, &attribute_block)
          }.to raise_error(/does not support anonymous generation/)
        end

        it 'passes the correct reference to the created attribute' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, type,  attribute_options, &attribute_block)
        end

      end

    end

  end

end
