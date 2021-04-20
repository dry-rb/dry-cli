# frozen_string_literal: true

require_relative "support/coverage"

$LOAD_PATH.unshift "lib"
require "dry/cli"
require_relative "./support/rspec"

%w[support].each do |dir|
  Dir[File.join(Dir.pwd, "spec", dir, "**", "*.rb")].each do |file|
    unless file["support/warnings.rb"]
      require_relative file
    end
  end
end
