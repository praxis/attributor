# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "attributor"
  gem.homepage = "http://github.com/blanquer/attributor"
  gem.license = "MIT"
  gem.summary = %Q{one-line summary of your gem}
  gem.description = %Q{longer description of your gem}
  gem.email = "blanquer@rightscale.com"
  gem.authors = ["RightScale"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.rcov = true
  spec.rcov_opts = %w{-Ispec --exclude gems\/,spec\/,doc\/}
end

RSpec::Core::RakeTask.new(:simplecov) do |spec|
  # Configured in spec_helper.rb
end

# 'rake spec' should do the same as 'rake rcov'
if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new("1.9")
  task :spec => :rcov
else
  task :spec => :simplecov
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
