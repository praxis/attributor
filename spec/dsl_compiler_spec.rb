require File.join(File.dirname(__FILE__), 'spec_helper.rb')

describe Attributor::DSLCompiler do
  let(:target) { double('model', attributes: {}) }

  let(:dsl_compiler_options) { {} }
  subject(:dsl_compiler) { Attributor::DSLCompiler.new(target, **dsl_compiler_options) }

  let(:attribute_name) { :name }
  let(:type) { Attributor::String }

  let!(:reference_attributes) { Turducken.attributes }
  let(:reference_type) { reference_attribute.type }
  let(:reference_attribute_options) { reference_attribute.options }
  let(:reference_attribute) { reference_attributes[attribute_name] }

  context '#attribute' do
    let(:attribute_options) { {} }

    let(:expected_options) { attribute_options }
    let(:expected_type) { type }

    context 'when not not given a block for a sub-definition' do
      context 'without a reference' do
        it 'raises an error for a missing type' do
          expect do
            dsl_compiler.attribute(attribute_name)
          end.to raise_error(/Type for attribute with name: name could not be determined/)
        end

        it 'creates an attribute given a name and type' do
          expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, type)
        end

        it 'creates an attribute given a name, type, and options' do
          expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, type, **attribute_options)
        end
      end

      context 'with a reference' do
        let(:dsl_compiler_options) { { reference: Turducken } }

        context 'with no options' do
          let(:expected_options) { reference_attribute_options }

          it 'creates an attribute with the inherited type' do
            expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
            dsl_compiler.attribute(attribute_name)
          end
        end

        context 'with options' do
          let(:attribute_options) { { description: 'some new description', required: true } }
          let(:expected_options) { reference_attribute_options.merge(attribute_options) }

          before do
            expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
          end

          it 'creates an attribute with the inherited type and merged options' do
            dsl_compiler.attribute(attribute_name, **attribute_options)
          end

          it 'accepts explicit nil type' do
            dsl_compiler.attribute(attribute_name, nil, **attribute_options)
          end
        end

        context 'for a referenced Model attribute' do
          let(:attribute_name) { :turkey }
          let(:expected_type) { Turkey }
          let(:expected_options) { reference_attribute_options.merge(attribute_options) }

          it 'creates an attribute with the inherited type' do
            expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
            dsl_compiler.attribute(attribute_name)
          end
        end
      end
    end

    context 'when given a block for sub-attributes' do
      let(:attribute_block) { proc {} }
      let(:attribute_name) { :turkey }
      let(:type) { Attributor::Struct }
      let(:expected_type) { Attributor::Struct }

      context 'without a reference' do
        it 'defaults type to Struct' do
          expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, &attribute_block)
        end
      end

      context 'with a reference that contains the same name attribute' do
        before { expect(dsl_compiler_options[:reference].attributes).to have_key(attribute_name) }
        let(:dsl_compiler_options) { { reference: Turducken } }
        let(:expected_options) do
          reference_attribute_options.merge(attribute_options).merge(reference: reference_type)
        end

        it 'fails, since the inherited type is a fully defined struct, which cannot be redefined by a block' do
          expect{dsl_compiler.attribute(attribute_name, **attribute_options, &attribute_block)}.to raise_error(/Invalid redefinition of attributes for an already existing type/)
        end
      end

      context 'with a reference that does NOT contains the same name attribute' do
        before { expect(dsl_compiler_options[:reference].attributes).to_not have_key(attribute_name) }
        let(:dsl_compiler_options) { { reference: Person } }
        let(:expected_options) { attribute_options }
        
        it 'sets the type of the attribute to Struct (and doe NOT the options from the named ref attribute)' do
          expect(Attributor::Attribute).to receive(:new)
            .with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, **attribute_options, &attribute_block)
        end

        it 'same as above, picks Struct and just brings in the attr options' do
          expect(Attributor::Attribute).to receive(:new).with(expected_type, expected_options)
          dsl_compiler.attribute(attribute_name, type, **attribute_options, &attribute_block)
        end
      end
    end
  end
  context 'type resolution, option inheritance for attributes with and without references' do
    # Overall strategy
    # 1) When no type is specified:
    #   1.1) if it is a leaf (no block)
    #     1.1.1) with an reference with an attr with the same name
    #          - type copied from reference
    #          - reference options are inherited as well (and can be overridden by local attribute ones)
    #     1.1.2) without a ref (or the ref does not have same attribute name)
    #          - Fail. Cannot determine type
    #   1.2) if it has a block
    #     1.2.1) with an reference with an attr with the same name
    #          - Fail, as the reference would be a full type, and we cannot merge it with the block
    #     1.2.2) without a ref (or the ref does not have same attribute name)
    #          - defaulted to Struct (if you meant Collection.of(Struct) things would fail later somehow)
    #          - options are NOT inherited at all (This is something we should ponder more about)
    # 2) When type is specified:
    #   2.1) if it is a leaf (no block)
    #     - ignore ref if there is one (with or without matching attribute name).
    #     - simply use provided type, and provided options (no inheritance)
    #   2.2) if it has a block
    #     - Same as above: use type and options provided, ignore ref if there is one (with or without matching attribute name).

    let(:mytype) do 
      Class.new(Attributor::Struct, &myblock)
    end
    context 'with no explicit type specified' do
      context 'without a block (if it is a leaf)' do
        context 'that has a reference with an attribute with the same name' do
          let(:myblock) { 
            Proc.new do
              attributes reference: Duck do
                attribute :age, required: true, min: 42
              end
            end
          }
          it 'uses type from reference' do
            expect(mytype.attributes).to have_key(:age)
            expect(mytype.attributes[:age].type).to eq(Duck.attributes[:age].type)
          end
          it 'copies over reference options and allows the attribute to override/add some' do
            merged_options = Duck.attributes[:age].options.merge(required: true, min: 42)
            expect(mytype.attributes[:age].options).to include(merged_options)
          end
        end
        context 'with a reference, but that does not have a matching attribute name' do
          let(:myblock) { 
            Proc.new do
              attributes reference: Cormorant do
                attribute :age
              end
            end
          }
          it 'fails resolving' do
            expect{mytype.attributes}.to raise_error(/Type for attribute with name: age could not be determined./)
          end
        end
        context 'without a reference' do
          let(:myblock) { 
            Proc.new do
              attributes do
                attribute :age
              end
            end
          }
          it 'fails resolving' do
            expect{mytype.attributes}.to raise_error(/Type for attribute with name: age could not be determined./)
          end
        end
      end
      context 'with block (if it is NOT a leaf)' do
        context 'that has a reference with an attribute with the same name' do
          let(:myblock) { 
            Proc.new do
              attributes reference: Duck do
                attribute :age do
                  attribute :foobar, Integer
                end
              end
            end
          }
          it 'fails resolving' do
            expect{mytype.attributes}.to raise_error(/Invalid redefinition of attributes for an already existing type/)
          end
          # context 'in the unlikely case that the reference type has an anonymous Struct (or collection of)' do
          #   let(:myblock) { 
          #     Proc.new do
          #       attributes reference: PersonBlueprint do
          #         attribute :funny_attribute, description: 'Funny business' do
          #           attribute :foobar, Integer, min: 42
          #         end
          #       end
          #     end
          #   }
          #   it 'correctly inherits it (same result as defaulting to Struct) and brings in the options' do
          #     expect(mytype.attributes).to have_key(:funny_attribute)
          #     # Resolves to Struct, and brings (and merges) the ref options with the attribute's
          #     expect(mytype.attributes[:funny_attribute].type).to be < Attributor::Struct
          #     merged_options = PersonBlueprint.attributes[:funny_attribute].options.merge(description: 'Funny business')
          #     expect(mytype.attributes[:funny_attribute].options).to include(merged_options)
          #     # And the nested attribute is correctly resolved as well, and ensures options are there
          #     expect(mytype.attributes[:funny_attribute].type.attributes[:foobar].type).to eq(Attributor::Integer)
          #     expect(mytype.attributes[:funny_attribute].type.attributes[:foobar].options).to eq(min: 42)
          #   end
          # end
        end
        context 'with a reference, but that does not have a matching attribute name' do
          let(:myblock) { 
            Proc.new do
              attributes reference: Cormorant do
                attribute :age, description: 'I am redefining' do
                  attribute :foobar, Integer, min: 42
                end
              end
            end
          }
          it 'correctly defaults to Struct uses only the local options (same exact as if it had no reference)' do
            expect(mytype.attributes).to have_key(:age)
            age_attribute = mytype.attributes[:age]
            # Resolves to Struct
            expect(age_attribute.type).to be < Attributor::Struct
            # does NOT brings any ref options 
            expect(age_attribute.options).to  eq(description: 'I am redefining')
            # And the nested attribute is correctly resolved as well, and ensures options are there
            expect(age_attribute.type.attributes[:foobar].type).to eq(Attributor::Integer)
            expect(age_attribute.type.attributes[:foobar].options).to eq(min: 42)
          end
        end
        context 'without a reference' do
          let(:myblock) { 
            Proc.new do
              attributes do
                attribute :age, description: 'I am redefining' do
                  attribute :foobar, Integer, min: 42
                end
              end
            end
          }
          it 'correctly defaults to Struct uses only the local options' do
            expect(mytype.attributes).to have_key(:age)
            age_attribute = mytype.attributes[:age]
            # Resolves to Struct
            expect(age_attribute.type).to be < Attributor::Struct
            # does NOT brings any ref options 
            expect(age_attribute.options).to  eq(description: 'I am redefining')
            # And the nested attribute is correctly resolved as well, and ensures options are there
            expect(age_attribute.type.attributes[:foobar].type).to eq(Attributor::Integer)
            expect(age_attribute.type.attributes[:foobar].options).to eq(min: 42)
          end
        end
      end
    end
    context 'with an explicit type specified' do
      context 'without a reference' do
        let(:myblock) { 
          Proc.new do
            attributes do
              attribute :age, String, description: 'I am a String now'
            end
          end
        }
        it 'always uses the provided type and local options specified' do
          expect(mytype.attributes).to have_key(:age)
          age_attribute = mytype.attributes[:age]
          # Resolves to String
          expect(age_attribute.type).to eq(Attributor::String)
          # copies local options
          expect(age_attribute.options).to  eq(description: 'I am a String now')
        end
      end
      context 'with a reference' do
        let(:myblock) { 
          Proc.new do
            attributes reference: Duck do
              attribute :age, String, description: 'I am a String now'
            end
          end
        }
        it 'always uses the provided type and local options specified (same as if it had no reference)' do
          expect(mytype.attributes).to have_key(:age)
          age_attribute = mytype.attributes[:age]
          # Resolves to String
          expect(age_attribute.type).to eq(Attributor::String)
          # copies local options
          expect(age_attribute.options).to  eq(description: 'I am a String now')
        end
      end
      context 'always uses the type and options specified ignoring any reference if there is one' do
      end
    end
    context 'no reference no type for leaf => error' do
      let(:myblock) { Proc.new do
        attributes do
          attribute :name
        end
      end }
      it 'works' do
        expect{mytype.attributes}.to raise_error(/Type for attribute with name: name could not be determined./)
      end
    end
  end
end
