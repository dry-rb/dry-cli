# frozen_string_literal: true

module RSpec
  module Support
    module Helpers
      def capture_output
        require "stringio"
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

      # Runs the block with `$stdout` swapped for the given stream, then puts it back
      def with_stdout(stream)
        original = $stdout
        $stdout = stream
        yield
      ensure
        $stdout = original
      end

      # Runs the block with the given environment variables set, then puts ENV back
      def with_env(vars)
        original = ENV.to_hash
        ENV.update(vars)
        yield
      ensure
        ENV.replace(original)
      end

      def capture_error
        require "stringio"
        error = StringIO.new
        original_stderr = $stderr
        $stderr = error
        yield
        error.string
      rescue SystemExit
        error.string
      ensure
        $stderr = original_stderr
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Support::Helpers)
end
