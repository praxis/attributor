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

  config.after do
    # TODO: need to support this better in Skeletor somehow too.
    Thread.current[:_attributor_attribute_resolver] = nil
  end

end
