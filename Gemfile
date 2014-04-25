source 'https://rubygems.org'

gem 'hashie'
gem 'randexp'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem 'rspec'
  gem 'yard', '~> 0.8.7'
  gem 'backports' # yardstick depends on this, but doesn't declare it
  gem 'yardstick'
  gem 'redcarpet', '< 3.0'
  gem 'rdoc', '~> 3.12'
  gem 'bundler'
  gem 'jeweler', '~> 1.8.3' # right_develop brings in old rake version, which is incompatible with newer jeweler
  gem 'right_develop', :git => 'git@github.com:rightscale/right_develop.git'
  gem 'ruby-prof'

  gem 'rake-notes'

  gem 'simplecov'
  gem 'guard'
  gem 'guard-rspec'

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'
end


group :test do
  gem 'fuubar'
end
