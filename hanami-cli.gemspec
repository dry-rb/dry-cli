# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/cli/version'

Gem::Specification.new do |spec|
  spec.name          = "hanami-cli"
  spec.version       = Hanami::Cli::VERSION
  spec.authors       = ["Luca Guidi"]
  spec.email         = ["me@lucaguidi.com"]

  spec.summary       = "Hanami CLI"
  spec.description   = "Hanami framework to build command line interfaces with Ruby"
  spec.homepage      = "http://hanamirb.org"

  spec.metadata['allowed_push_host'] = "https://rubygems.org"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "hanami-utils",    "~> 1.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
