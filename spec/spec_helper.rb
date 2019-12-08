# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'
  end
end

$LOAD_PATH.unshift "lib"
require "hanami/utils"
require "hanami/devtools/unit"
require "dry/cli"
require_relative "./support/rspec"
Hanami::Utils.require!("spec/support/**/*.rb")
