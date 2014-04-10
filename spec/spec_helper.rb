Encoding.default_external = Encoding::UTF_8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# Configure simplecov gem (must be here at top of file)
if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('1.9')
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec' # Don't include RSpec stuff
    add_group 'Types', 'lib/attributor/types'
  end
end

# Configure some Ruby 1.8-specific stuff
if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('1.9')
  # Needed so that 'bundle exec rake rcov' actually runs the specs
  require 'rspec/autorun'
end

require 'rspec'
require 'attributor'

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

