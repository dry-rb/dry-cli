# frozen_string_literal: true

module RSpec
  module Support
    module Helpers
      def capture_output
        require 'stringio'
        output = StringIO.new
        original_stdout = $stdout
        $stdout = output
        yield
        output.string
      rescue SystemExit
        output.string
      ensure
        $stdout = original_stdout
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Support::Helpers)
end
