# frozen_string_literal: true

source 'https://rubygems.org'

eval_gemfile 'Gemfile.devtools'

gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end
