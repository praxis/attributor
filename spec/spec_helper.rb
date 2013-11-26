require 'require_relative' if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('1.9')

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('1.9')
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec' # Don't include RSpec stuff
    add_group 'Types', 'lib/attributor/types'
  end
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

