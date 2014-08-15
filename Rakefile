# encoding: utf-8


require 'bundler/setup'
#begin
#  Bundler.setup(:default, :development)
#rescue Bundler::BundlerError => e
#  $stderr.puts e.message
#  $stderr.puts "Run `bundle install` to install missing gems"
#  exit e.status_code
#end
require 'rake'

require 'rake/notes/rake_task'

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run RSpec code examples with simplecov"
RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = ["-c"]
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
