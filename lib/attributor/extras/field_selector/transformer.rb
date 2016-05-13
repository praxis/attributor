module Attributor
  class FieldSelector
    class Transformer < Parslet::Transform
      rule(field: simple(:field_token), children: subtree(:children_tree)) do
        cs = if children_tree.empty?
               true
             else
               children_tree.each_with_object({}) do |item, hash|
                 hash.merge! item
               end
             end
        { field_token.to_sym => cs }
      end

      rule(csv: subtree(:csv_tree)) do
        case csv_tree
        when ::Hash
          csv_tree
        when Array
          csv_tree.each_with_object({}) do |item, hash|
            hash.merge! item
          end
        else
          raise "Oops...didn't know this could happen! (this is not a Hash or an Array?). Got a #{csv_tree.class.name} : #{csv_tree.inspect}"
        end
      end
    end
  end
end
