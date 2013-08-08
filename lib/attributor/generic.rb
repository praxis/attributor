module Attributor
    
    class Struct < Base
  
      class << self
        
      def parse_block(&block)
        sub_definition=StructDefinition.new()
        sub_definition.parse_block(&block) if block
        return sub_definition
      end
      



