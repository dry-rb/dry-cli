# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/cli/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami-cli"
  spec.version       = Hanami::CLI::VERSION
  spec.authors       = ["Luca Guidi"]
  spec.email         = ["me@lucaguidi.com"]
  spec.licenses      = ["MIT"]

  spec.summary       = "Hanami CLI"
  spec.description   = "Hanami framework to build command line interfaces with Ruby"
  spec.homepage      = "http://hanamirb.org"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "https://github.com/hanami/cli"

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.add_dependency "hanami-utils",    "~> 2.0.alpha"
  spec.add_dependency "concurrent-ruby", "~> 1.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake",  "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.7"
end
