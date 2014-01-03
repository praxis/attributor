source 'https://rubygems.org'

gem 'hashie'
gem 'randexp'

gem 'require_relative', :platforms => :ruby_18

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
  gem 'pry'
  gem 'ruby-prof'

  platforms :ruby_18 do
    gem "ruby-debug-pry", :require => "ruby-debug/pry"
    gem 'rcov'
  end

  platforms :ruby_19, :ruby_20, :ruby_21 do
    gem 'pry-debugger'
    gem 'simplecov'
    gem 'guard'
    gem 'guard-rspec'
  end
end
