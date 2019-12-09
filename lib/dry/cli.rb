# frozen_string_literal: true

# Dry
#
# @since 0.1.0
module Dry
  # General purpose Command Line Interface (CLI) framework for Ruby
  #
  # @since 0.1.0
  class CLI
    require 'dry/cli/version'
    require 'dry/cli/errors'
    require 'dry/cli/command'
    require 'dry/cli/registry'
    require 'dry/cli/parser'
    require 'dry/cli/usage'
    require 'dry/cli/banner'

    # Check if command
    #
    # @param command [Object] the command to check
    #
    # @return [TrueClass,FalseClass] true if instance of `Dry::CLI::Command`
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
    # @param registry [Dry::CLI::Registry] a registry
    #
    # @return [Dry::CLI] the new instance
    # @since 0.1.0
    def initialize(registry)
      @commands = registry
    end

    # Invoke the CLI
    #
    # @param arguments [Array<string>] the command line arguments (defaults to `ARGV`)
    # @param out [IO] the standard output (defaults to `$stdout`)
    #
    # @since 0.1.0
    def call(arguments: ARGV, out: $stdout)
      result = commands.get(arguments)

      if result.found?
        command, args = parse(result, out)

        result.before_callbacks.run(command, args)
        command.call(args)
        result.after_callbacks.run(command, args)
      else
        usage(result, out)
      end
    end

    private

    # @since 0.1.0
    # @api private
    attr_reader :commands

    # Parse arguments for a command.
    #
    # It may exit in case of error, or in case of help.
    #
    # @param result [Dry::CLI::CommandRegistry::LookupResult]
    # @param out [IO] sta output
    #
    # @return [Array<Dry:CLI::Command, Array>] returns an array where the
    #   first element is a command and the second one is the list of arguments
    #
    # @since 0.1.0
    # @api private
    def parse(result, out)
      command = result.command
      return [command, result.arguments] unless command?(command)

      result = Parser.call(command, result.arguments, result.names)

      if result.help?
        Banner.call(command, out)
        exit(0)
      end

      if result.error?
        out.puts(result.error)
        exit(1)
      end

      [command, result.arguments]
    end

    # Prints the command usage and exit.
    #
    # @param result [Dry::CLI::CommandRegistry::LookupResult]
    # @param out [IO] sta output
    #
    # @since 0.1.0
    # @api private
    def usage(result, out)
      Usage.call(result, out)
      exit(1)
    end

    # Check if command
    #
    # @param command [Object] the command to check
    #
    # @return [TrueClass,FalseClass] true if instance of `Dry::CLI::Command`
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
