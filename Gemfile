# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "backports", "~> 3.15.0", require: false
gem "dry-types", require: false

unless ENV["CI"]
  gem "yard", require: false
end

# Runs a CLI in-process through Dry::CLI::Launcher in spec/integration/launcher_spec.rb
gem "aruba", require: false
