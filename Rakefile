# encoding: utf-8
require 'bundler/setup'
require 'rake'

require 'rspec/core'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'rake/notes/rake_task'


desc "Run RSpec code examples with simplecov"
RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = ["-c"]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc "console"
task :console do
  require 'bundler'
  Bundler.require(:default, :development, :test)
  require_relative 'lib/attributor'
  pry
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
