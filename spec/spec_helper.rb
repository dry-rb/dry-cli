# frozen_string_literal: true

require_relative "support/coverage"

$LOAD_PATH.unshift "lib"
require "dry/cli"
require_relative "support/rspec"

Dir.glob(Pathname.new(__dir__).join("support", "**", "*.rb")).each do |file|
  require_relative file
end

RSpec.configure do |config|
  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
