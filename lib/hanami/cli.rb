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
    # rubocop:disable Metrics/MethodLength
    def call(arguments: ARGV, out: $stdout, err: nil, kernel: nil)
      @kernel = kernel || Kernel

      original_argv = ARGV.dup

      result = commands.get(arguments)

      if result.found?
        call_command(result, out)
      else
        exit_code = 0
        invalid_commands = original_argv.reject { |a| a.start_with?('-') }
        if invalid_commands.size.positive?
          report_unknown_command(err, invalid_commands)
          exit_code = 1
        end
        usage(result, out, exit_code)
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    # Reports unknown commands to the output
    #
    # @param err [IO, NilClass] the standard output or the standard error or nil (default)
    # @param invalid_commands [Array<String>] array of invalid commands
    #
    # @since x.x.x
    # @api private
    def report_unknown_command(err, invalid_commands)
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
