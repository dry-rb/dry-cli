# frozen_string_literal: true

# Ensure that any existing style-related env vars do not conflict with our styling tests.
RSpec.configure do |config|
  config.before :suite do
    ENV.delete("NO_COLOR")
    ENV.delete("FORCE_COLOR")
  end
end
