# frozen_string_literal: true

module Attributor
  class FieldSelector
    class Parser < Parslet::Parser
      rule(:simple_name) { match('[a-zA-Z0-9_]').repeat(1) }
      rule(:item) { simple_name.as(:field) >> parenthesized.repeat(0).as(:children) }
      rule(:parenthesized) { str('{') >> csv >> str('}') }
      rule(:csv) { (item >> (str(',') >> item).repeat(0)).as(:csv) }
      root(:csv)
    end
  end
end
