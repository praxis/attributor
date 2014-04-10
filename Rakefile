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

require 'rake/notes/rake_task'


Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "attributor"
  gem.homepage = "https://github.com/rightscale/attributor"
  gem.license = "RightScale, Inc."
  gem.summary = "Attributor is a component of RESTful Skeletor"
  gem.description = "makes building Resource-based Web APIs a walk in the park"
  gem.email = "salmon.sprint@rightscale.com"
  gem.authors = ["RightScale, Inc."]
  gem.files.exclude 'spec/**/*' # exclude specs
  gem.files.exclude '**/.gitignore'
  gem.files.exclude 'Gemfile.lock'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run RSpec code examples with simplecov"
RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = ["-c"]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'right_support'

if require_succeeds?('right_develop')
  RightDevelop::CI::RakeTask.new
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
