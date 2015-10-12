
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'attributor/version'

Gem::Specification.new do |spec|
  spec.name = "attributor"
  spec.version       = Attributor::VERSION
  spec.authors = ["Josep M. Blanquer","Dane Jensen"]
  spec.summary = "A powerful attribute and type management library for Ruby"
  spec.email = ["blanquer@gmail.com","dane.jensen@gmail.com"]

  spec.homepage = "https://github.com/rightscale/attributor"
  spec.license = "MIT"
  spec.required_ruby_version = ">=2.1"

  spec.require_paths = ["lib"]
  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_runtime_dependency(%q<hashie>, ["~> 3"])
  spec.add_runtime_dependency(%q<randexp>, ["~> 0"])
  spec.add_runtime_dependency(%q<activesupport>, ['>= 3'])

  spec.add_development_dependency(%q<rspec>, ["< 2.99"])
  spec.add_development_dependency(%q<yard>, ["~> 0.8.7"])
  spec.add_development_dependency(%q<backports>, ["~> 3"])
  spec.add_development_dependency(%q<yardstick>, ["~> 0"])
  spec.add_development_dependency(%q<redcarpet>, ["< 3.0"])
  spec.add_development_dependency(%q<bundler>, [">= 0"])
  spec.add_development_dependency(%q<rake-notes>, ["~> 0"])
  spec.add_development_dependency(%q<simplecov>, ["~> 0"])
  spec.add_development_dependency(%q<guard>, ["~> 2"])
  spec.add_development_dependency(%q<guard-rspec>, ["~> 4"])
  spec.add_development_dependency(%q<pry>, ["~> 0"])
  spec.add_development_dependency(%q<pry-byebug>, ["~> 1"])
  spec.add_development_dependency(%q<pry-stack_explorer>, ["~> 0"])
  spec.add_development_dependency(%q<fuubar>, ["~> 1"])

  spec.add_development_dependency(%q<parslet>, [">= 0"])
end
