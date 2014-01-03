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
  gem 'simplecov', :require => false
  gem 'pry'
  gem 'ruby-prof'

  gem 'rake-notes'

  platforms :ruby_18 do
    # pry debugger
    gem "ruby-debug-pry", :require => "ruby-debug/pry"
    # code coverage
    gem 'rcov'
  end

  platforms :ruby_19 do
    # pry debugger
    gem 'pry-debugger'
    # code coverage
    gem 'simplecov'
    # Guard (Ruby 1.9 only)
    gem 'guard'
    gem 'guard-rspec'
  end
end


group :test do
  gem 'fuubar'
end
