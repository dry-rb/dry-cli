# Hanami
#
# @since 0.1.0
module Hanami
  # General purpose Command Line Interface (CLI) framework for Ruby
  #
  # @since 0.1.0
  class CLI
    require "hanami/cli/version"
    require "hanami/cli/errors"
    require "hanami/cli/command"
    require "hanami/cli/registry"
    require "hanami/cli/parser"
    require "hanami/cli/usage"
    require "hanami/cli/banner"

    # Check if command
    #
    # @param command [Object] the command to check
    #
    # @return [TrueClass,FalseClass] true if instance of `Hanami::CLI::Command`
    #
    # @since 0.1.0
    # @api private
    def self.command?(command)
      case command
      when Class
        command.ancestors.include?(Command)
      else
        command.is_a?(Command)
      end
    end

    # Create a new instance
    #
    # @param registry [Hanami::CLI::Registry] a registry
    #
    # @return [Hanami::CLI] the new instance
    # @since 0.1.0
    def initialize(registry)
      @commands = registry
    end

    # Invoke the CLI
    #
    # @param arguments [Array<string>] the command line arguments (defaults to `ARGV`)
    # @param out [IO] the standard output (defaults to `$stdout`)
    # @param err [IO, NilClass] the standard output or the standard error or nil (default)
    # @param kernel [Module, NilClass] optional replacement for Kernel, on which #exit() is called.
    #
    # @since 0.1.0
    def call(arguments: ARGV, out: $stdout, err: $stderr, kernel: nil)
      @kernel = kernel || Kernel
      result = commands.get(arguments)

      if result.found?
        call_command(result, out)
      else
        handle_unknown_command(ARGV.dup, result, out, err)
      end
    end

    private

    # Attempt to find the CLI argument that we are unable to map to an existing
    # command, and inform the user about which command or subcommand is invalid.
    #
    # @param argv [Array<String>] a copy of command line arguments
    # @param result [Hanami::CLI::CommandRegistry::LookupResult] an object containing result of ARGV parsing
    # @param out [IO] output stream
    # @param err [IO, NilClass] an optional error output stream
    #
    # @since x.x.x
    # @api private
    def handle_unknown_command(argv, result, out, err = $stderr)
      # default to a successful exit code.
      exit_code = 0

      # First, remove any arguments that follow any possible "--" argument,
      # then reject any flags starting with "-", and then finally, remove any names
      # that matched super-commands (commands with their own subcommands). If the resulting
      # list is non-empty, anything there is the invalid command we'll be reporting.
      invalid_commands = argv[0...(argv.index('--') || argv.size)]
                         .reject { |a| a.start_with?('-') } - result.names

      if invalid_commands.size.positive?
        report_unknown_command(invalid_commands, err)
        exit_code = 1
      end
      usage(result, out, exit_code)
    end

    # Reports unknown commands to the output
    #
    # @param err [IO, NilClass] the standard output or the standard error or nil (default)
    # @param invalid_commands [Array<String>] array of invalid commands
    #
    # @since x.x.x
    # @api private
    def report_unknown_command(invalid_commands, err)
      err&.puts("Error:\n")
      err&.puts("  Unknown command(s): #{invalid_commands.join(', ')}")
      err&.puts
    end

    # Calls the command and runs callbacks.
    #
    # @param result [Hanami::CLI::CommandRegistry::LookupResult]
    # @param out [IO] sta output
    #
    # @since x.x.x
    # @api private
    def call_command(result, out)
      command, args = parse(result, out)

      result.before_callbacks.run(command, args)
      command.call(args)
      result.after_callbacks.run(command, args)
    end

    # @since 0.1.0
    # @api private
    attr_reader :commands, :kernel

    # Parse arguments for a command.
    #
    # It may exit in case of error, or in case of help.
    #
    # @param result [Hanami::CLI::CommandRegistry::LookupResult]
    # @param out [IO] sta output
    #
    # @return [Array<Hanami:CLI::Command, Array>] returns an array where the
    #   first element is a command and the second one is the list of arguments
    #
    # @since 0.1.0
    # @api private
    #
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def parse(result, out)
      command = result.command
      return [command, result.arguments] unless command?(command)

      result = Parser.call(command, result.arguments, result.names)

      if result.help?
        Banner.call(command, out)
        kernel&.send(:exit, 0)
      end

      if result.error?
        out.puts(result.error)
        kernel&.send(:exit, 1)
      end

      [command, result.arguments]
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Prints the command usage and exit.
    #
    # @param result [Hanami::CLI::CommandRegistry::LookupResult]
    # @param out [IO] sta output
    #
    # @since 0.1.0
    # @api private
    def usage(result, out, exit_code = 1)
      Usage.call(result, out)
      kernel&.send(:exit, exit_code)
    end

    # Check if command
    #
    # @param command [Object] the command to check
    #
    # @return [TrueClass,FalseClass] true if instance of `Hanami::CLI::Command`
    #
    # @since 0.1.0
    # @api private
    #
    # @see .command?
    def command?(command)
      CLI.command?(command)
    end
  end
end
