
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'attributor/version'

Gem::Specification.new do |spec|
  spec.name = 'attributor'
  spec.version = Attributor::VERSION
  spec.authors = ['Josep M. Blanquer', 'Dane Jensen']
  spec.summary = 'A powerful attribute and type management library for Ruby'
  spec.email = ['blanquer@gmail.com', 'dane.jensen@gmail.com']

  spec.homepage = 'https://github.com/rightscale/attributor'
  spec.license = 'MIT'
  spec.required_ruby_version = '>=2.1'

  spec.require_paths = ['lib']
  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_runtime_dependency('hashie', ['~> 3'])
  spec.add_runtime_dependency('randexp', ['~> 0'])
  spec.add_runtime_dependency('activesupport', ['>= 3'])

  spec.add_development_dependency('rspec', ['< 2.99'])
  spec.add_development_dependency('yard', ['~> 0.8.7'])
  spec.add_development_dependency('backports', ['~> 3'])
  spec.add_development_dependency('yardstick', ['~> 0'])
  spec.add_development_dependency('redcarpet', ['< 3.0'])
  spec.add_development_dependency('bundler', ['>= 0'])
  spec.add_development_dependency('rake-notes', ['~> 0'])
  spec.add_development_dependency('coveralls')
  spec.add_development_dependency('guard', ['~> 2'])
  spec.add_development_dependency('guard-rspec', ['~> 4'])
  spec.add_development_dependency('pry', ['~> 0'])
  spec.add_development_dependency('pry-byebug', ['~> 1'])
  spec.add_development_dependency('pry-stack_explorer', ['~> 0'])
  spec.add_development_dependency('fuubar', ['~> 1'])
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'guard-rubocop'

  spec.add_development_dependency('parslet', ['>= 0'])
end
