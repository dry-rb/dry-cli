# frozen_string_literal: true

module Dry
  class CLI
    # Help users to build a shell completion script by searching commands based on a prefix
    #
    # @since 1.3.0
    class ShellCompletion < Command
      desc "Help you to build a shell completion script by searching commands based on a prefix"

      argument :prefix, desc: "Command name prefix", required: true
    end
  end
end
