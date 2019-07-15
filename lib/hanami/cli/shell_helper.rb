# frozen_string_literal: true

module Hanami
  class CLI
    # A class for executing arbitrary shell commands and outputting what was executed.
    #
    # @since x.x.x
    class ShellHelper
      # @since x.x.x
      # @api private
      RUN_OUTPUT_FORMATTER = "         run  %s\n"

      # @since x.x.x
      # @api public
      def initialize(out: $stdout)
        @out = out
      end

      # @since x.x.x
      # @api private
      attr_reader :out

      # @api public
      def execute(command, **opts)
        Kernel.system(command, opts)
        out.puts(RUN_OUTPUT_FORMATTER % command)
      end
    end
  end
end
