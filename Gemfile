source 'https://rubygems.org'

gem 'hashie'
gem 'randexp'

gem 'require_relative', :platform => :ruby_18

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'rspec'
  gem 'yard', '~> 0.8.7'
  gem 'backports' # yardstick depends on this but doesn't declare it
  gem 'yardstick'
  gem 'redcarpet', '< 3.0'
  gem 'rdoc', '~> 3.12'
  gem 'bundler'
  gem 'jeweler', '~> 1.8.4'
  gem 'simplecov', :require => false
  gem 'guard'
  gem 'guard-rspec'
  gem 'pry'
  gem "ruby-debug-pry", :platform => :ruby_18, :require => "ruby-debug/pry"
  gem 'pry-debugger', :platform => :ruby_19
  gem 'ruby-prof'
end
