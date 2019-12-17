# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'
  end
end

$LOAD_PATH.unshift 'lib'
require 'dry/cli'
require_relative './support/rspec'

%w[support unit].each do |dir|
  Dir[File.join(Dir.pwd, 'spec', dir, '**', '*.rb')].each { |file| require_relative file }
end
