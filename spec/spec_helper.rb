$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'simplecov'

SimpleCov.start do
  add_filter 'spec' # Don't include RSpec stuff
  add_group 'Types', 'lib/attributor/types'
end

require 'rspec'
require 'attributor'

require 'pry'


# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

  config.around(:each) do |example|
    Attributor::AttributeResolver.current = Attributor::AttributeResolver.new
    example.run
    Attributor::AttributeResolver.current = nil
  end

end
