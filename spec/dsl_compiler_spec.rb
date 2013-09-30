require_relative 'spec_helper'


# RULES FOR ATTRIBUTES
#   The type of an attribute is:
#     the specified type
#     inferred from a reference type.
#       it should always end up being an anonymous type, otherwise the Model class will explode
#     Struct if a block is given

#   The reference option for an attribute is passed if a block is given


describe Attributor::DSLCompiler do


  let(:dsl_compiler_options) { {} }
  subject(:dsl_compiler) { Attributor::DSLCompiler.new(dsl_compiler_options) }



  context 'adding a typed attribute' do
    it 'works'
  end


  it 'needs specs for nested attributes'
  it 'needs specs for anonymous structs if the spec above did not cover those well enough'


  let(:attribute_name) { "name" }
  let(:attribute_type) { Attributor::String }

  let!(:reference_attributes) { Turducken.definition.attributes }
  let(:reference_attribute_type) { reference_attribute.type }
  let(:reference_attribute_options) { reference_attribute.options }
  let(:reference_attribute) {reference_attributes[attribute_name] }

  context '#attribute' do
    let(:attribute_options) { {} }

    let(:expected_options) { attribute_options }
    let(:expected_type) { attribute_type }


    context 'when not not given a block for a sub-definition' do


      context 'without a reference' do

        it 'raises an error for a missing type' do
          expect {
            dsl_compiler.attribute(attribute_name)
          }.to raise_error(/type not specified/)

        end

        it 'creates an attribute given a name and type' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, attribute_type)
        end


        it 'creates an attribute given a name, type, and options' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, attribute_type, attribute_options)
        end

      end


      context 'with a reference' do
        let(:dsl_compiler_options) { {reference: Turducken} }

        context 'with no options' do
          let(:expected_options) { reference_attribute_options }

          it 'creates an attribute with the inherited type' do
            Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
            dsl_compiler.attribute(attribute_name)
          end
        end

        context 'with options' do
          let(:attribute_options) { {description: "some new description", required: true} }
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
      let(:attribute_type) { Attributor::Struct }
      let(:expected_type) { Attributor::Struct }

      context 'without a reference' do
        it 'defaults type to Struct' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, &attribute_block)
        end
      end

      context 'with a reference' do
        let(:dsl_compiler_options) { {reference: Turducken} }
        let(:expected_options) do
            attribute_options.merge(reference:reference_attribute_type)
        end

        it 'is unhappy from somewhere else if you do not specify a type' do
          expect {
            dsl_compiler.attribute(attribute_name, attribute_options, &attribute_block)
          }.to raise_error(/does not support anonymous generation/)
        end

        it 'passes the correct reference to the created attribute' do
          Attributor::Attribute.should_receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, attribute_type,  attribute_options, &attribute_block)
        end

      end

    end

  end

end



# context 'inferring type from a reference' do
#   let(:reference_attributes) { Turducken.definition.attributes }
#   let(:reference_attribute) {reference_attributes[name] }
#   let(:reference_attribute_type) { reference_attribute.type }

#   subject(:inferred_type) { dsl_compiler.infer_type(attribute_name) }

#   context 'for simple attributes' do
#     let(:attribute_name) { "name" }

#     it { should be(reference_attribute_type) }


#     context 'for an unknown attribute name' do
#       it 'raises an error' do
#         expect {
#           dsl_compiler.attribute('unknown')
#         }.to raise_error(/can not inherit attribute/)
#       end
#     end
#   end



#   context 'determining type for reference option' do
#   end








#   context 'inheriting from a reference' do
#     let(:reference_attributes) { Turducken.definition.attributes }
#     let(:name) { "name" }
#     let(:name_attribute) {reference_attributes[name] }


#     shared_examples 'inheritance' do
#       context 'type' do
#       end
#     end

#     context 'passing only a name' do
#       subject(:attribute) { dsl_compiler.attribute(name)}
#       it 'inherits type' do
#         attribute.type.should be(chicken_attributes[name].type)
#       end
#       it 'inherits exact options' do
#         attribute.options.should == chicken_attributes[name].options
#       end

#       context 'for an unknown attribute name' do
#         it 'raises an error' do
#           expect {
#             dsl_compiler.attribute('unknown')
#           }.to raise_error(/can not inherit attribute/)
#         end
#       end
#     end


#     context 'passing name and options' do
#       subject(:attribute) { dsl_compiler.attribute(name, attribute_options)}

#       let(:attribute_options) { {required: true, regexp:/\w+@/} }

#       it 'inherits type' do
#         attribute.type.should == (chicken_attributes[name].type)
#       end

#       it 'merges inherited plus new options' do
#         attribute.options[:required].should == attribute_options[:required]
#         attribute.options[:description].should == chicken_attribute.options[:description]
#       end

#       it 'overrides duplicated options' do
#         attribute.options[:regexp].should_not == chicken_attribute.options[:regexp]
#         attribute.options[:regexp].should == attribute_options[:regexp]
#       end
#     end


#     context 'passing name, nil for type, and options' do
#       subject(:attribute) { dsl_compiler.attribute(name, nil, attribute_options)}

#       let(:attribute_options) { {required: true, regexp:/\w+@/} }

#       it 'inherits type' do
#         attribute.type.should == (chicken_attributes[name].type)
#       end

#       it 'merges inherited plus new options' do
#         attribute.options[:required].should == attribute_options[:required]
#         attribute.options[:description].should == chicken_attribute.options[:description]
#       end

#       it 'overrides duplicated options' do
#         attribute.options[:regexp].should_not == chicken_attribute.options[:regexp]
#         attribute.options[:regexp].should == attribute_options[:regexp]
#       end
#     end


#   end




# end
