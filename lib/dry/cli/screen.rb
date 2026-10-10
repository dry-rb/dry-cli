# frozen_string_literal: true

module Dry
  class CLI
    # One help screen on its way to being printed.
    #
    # The CLI builds a screen whenever it prints help, or a listing of commands in place of a
    # command it could not run. The screen then goes through the help renderer, which fills in its
    # {#text}, and the help filters in turn, each returning the screen it was given or a changed
    # copy of it (see {Dry::CLI::Config::Help}). The CLI prints the text of the screen the last
    # filter returns to {#io}, then exits with its {#status}.
    #
    # @!attribute [r] kind
    #   @return [Symbol] `:command` for the help of one command, or `:listing` for the commands
    #     registered at one level
    # @!attribute [r] reason
    #   @return [Symbol] why it is shown: `:help` when asked for with `-h` or `--help`,
    #     `:no_command` when the arguments stop at a group or namespace, or `:unknown` when they
    #     name no command
    # @!attribute [r] node
    #   @return [Dry::CLI::Tree::Node] the command, or the level, it describes
    # @!attribute [r] prog_name
    #   @return [String] the program name, and the names leading to {#node}, e.g. "foo db migrate"
    # @!attribute [r] long
    #   @return [Boolean] true for `--help`, false otherwise
    # @!attribute [r] arguments
    #   @return [Array<String>] the command line arguments, as given
    # @!attribute [r] suggestion
    #   @return [String, nil] the spell checker's suggestion, for an unknown command
    # @!attribute [r] text
    #   @return [String, nil] what is printed; nil until the renderer fills it in
    # @!attribute [r] status
    #   @return [Integer, nil] the exit status, or nil to print without exiting
    # @!attribute [r] stdout
    #   @return [Dry::CLI::Stream] the CLI's output
    # @!attribute [r] stderr
    #   @return [Dry::CLI::Stream] the CLI's error output
    #
    # @example A filter that shows help asked for with -h on stdout, with a status of 0
    #   ->(screen) { screen.reason == :help ? screen.with(status: 0) : screen }
    #
    # @api public
    # @since x.y.z
    Screen = Data.define(
      :kind, :reason, :node, :prog_name, :long, :arguments, :suggestion, :text, :status,
      :stdout, :stderr
    ) do
      # @return [Boolean] whether this describes one command
      def command? = kind == :command

      # @return [Boolean] whether this lists the commands at one level
      def listing? = kind == :listing

      # Where the text is printed: the output for a status of 0, and the error output otherwise.
      #
      # @return [Dry::CLI::Stream]
      def io
        status&.zero? ? stdout : stderr
      end
    end
  end
end
