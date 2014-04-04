require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Attributor::Polymorphic do
  class Human < Attributor::Struct
    attributes do
      attribute :type, Integer, values: [1], description: "Polymorphic discriminator"
      attribute :name, String
      attribute :phone, String
    end
  end
  class Animal < Attributor::Struct
    attributes do
      attribute :type, Integer, values: [2], description: "Polymorphic discriminator"
      attribute :name, String
    end
  end

  let(:polymorphic_block) { Proc.new{} }
  let(:polymorphic_opts) { {} }
  let(:poly_class) { Attributor::Polymorphic.on(:type) }

  it 'defaults the name field to :type and type of ::String' do
    Attributor::Polymorphic.discriminator_name.should == :type
    Attributor::Polymorphic.discriminator_type.should == ::String
  end
  
  context '#on' do
    context 'with a simple name' do
      subject { Attributor::Polymorphic.on(:my_type) }
      it 'creates the type class saving the passed name field and defaulting to ::String type' do
        subject.should be_a(::Class)
        subject.discriminator_name.should == :my_type
        subject.discriminator_type.should == ::String        
      end
    end
    context 'with a hash definition' do
      subject { Attributor::Polymorphic.on( {my_type: Integer} ) }
      it 'creates the type class saving the passed name field and defaulting to ::String type' do
        subject.should be_a(::Class)
        subject.discriminator_name.should == :my_type
        subject.discriminator_type.should == ::Integer
      end
    end

  end
  
  
  context '.construct' do
    subject { poly_class.construct(polymorphic_block,polymorphic_opts) }
    
    context 'given an empty DSL' do
      let(:polymorphic_block) { Proc.new{} }
      it 'creates an empty set of attributes from an empty block' do
        subject.should < Attributor::Polymorphic
        subject.polymorphic_attributes.should be_empty
      end
          
    end
    
    context 'given a real DSL block' do
      let(:poly_class) { Attributor::Polymorphic.on(:type => Integer) }
      let(:polymorphic_block) do 
        # Building a polymorphic test using non-string values in the discriminator type (for demonstration purposes)
        Proc.new do
          given 1, Human
          given 2, Animal
        end
        
      end
      it 'creates an internal polymorphic attribute for each stanza in the DSL block' do
        attributes = subject.polymorphic_attributes
        attributes.should_not be_empty
#        binding.pry
  #      HERE!!! use the debugger to call the new methods in polymorphic: example, load, validate...etc
        example = subject.example('safa')
        loaded = subject.load( example.dump )
        validated = subject.validate(loaded, 'asdf', nil)
        attributes.keys.should =~ [1, 2]
        
      end
    end
  end
  
  context '.given' do
    subject(:poly_attrs){ poly_class.polymorphic_attributes }
    
    it 'adds an attribute to the polymorphic_attributes hash' do
      poly_class.given :name1, String, values: ['one', 'two']

      poly_attrs.should have(1).items
      name1_attr = poly_attrs[:name1.to_s]
      name1_attr.type.should be(Attributor::String)
      name1_attr.options.should == { values: ['one', 'two'] }
    end
    
    it 'raises an error when redefining a type name' do
      poly_class.given :name1, String
      expect{
        poly_class.given :name1, String
      }.to raise_error(/type name that has already been defined/)
    end
    
  end
  
  context 'using it in an attribute' do
    
    it 'loads an allowed type for favorite _bird' do
      dup =  Person.example('seed').dump.dup
      dup[:favorite_bird] = Chicken.example('seed').dump
      dup[:address].delete :person # Because it is a recursive rendering (i.e. has "...")
      p = Person.load(dup)
      Person.validate(p,"ctx",nil)
    end
  end
  
end