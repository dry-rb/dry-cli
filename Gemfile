# frozen_string_literal: true

source 'https://rubygems.org'

eval_gemfile 'Gemfile.devtools'

gemspec

gem 'backports', '~> 3.15.0', require: false

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end
