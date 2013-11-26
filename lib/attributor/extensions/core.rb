
# Custom core patches for Ruby 1.8.x
if Attributor.check_ruby_version('<', '1.9')

# Ruby 1.8.x doesn't provide a Random module, so make a minimal version here
module Random
  def self.rand(x)
    Kernel.rand(x) + 1
  end

  def self.srand(s)
    Kernel.srand(s)
  end
end

# Ruby 1.8.x doesn't provide an Array#sample method, so alias it to Array#choice
class Array
  alias_method :sample, :choice
end

end
