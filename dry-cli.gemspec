# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-cli'
  spec.version       = Dry::CLI::VERSION
  spec.authors       = ['Luca Guidi']
  spec.email         = ['me@lucaguidi.com']
  spec.licenses      = ['MIT']

  spec.summary       = 'Dry CLI'
  spec.description   = 'Common framework to build command line interfaces with Ruby'
  spec.homepage      = 'http://dry-rb.org'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['source_code_uri'] = 'https://github.com/dry-rb/dry-cli'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_dependency 'concurrent-ruby', '~> 1.0'

  spec.add_development_dependency 'bundler', '>= 1.6', '< 3'
  spec.add_development_dependency 'rake',  '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
end
