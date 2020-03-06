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
    require 'dry/cli/inflector'

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
    # @param command_or_registry [Dry::CLI::Registry, Dry::CLI::Command]
    #   a registry or singular command
    # @param &block [Block] a configuration block for registry
    #
    # @return [Dry::CLI] the new instance
    # @since 0.1.0
    def initialize(command_or_registry = nil, &block)
      @kommand = command_or_registry if command?(command_or_registry)

      @registry =
        if block_given?
          anonymous_registry(&block)
        else
          command_or_registry
        end
    end

    # Invoke the CLI
    #
    # @param arguments [Array<string>] the command line arguments (defaults to `ARGV`)
    # @param out [IO] the standard output (defaults to `$stdout`)
    # @param err [IO] the error output (defaults to `$stderr`)
    #
    # @since 0.1.0
    def call(arguments: ARGV, out: $stdout, err: $stderr)
      @out, @err = out, err
      return perform_command(arguments) if kommand

      perform_registry(arguments)
    end

    private

    # @since 0.6.0
    # @api private
    attr_reader :registry

    # @since 0.6.0
    # @api private
    attr_reader :kommand

    # @since 0.6.0
    # @api private
    attr_reader :out

    # @since 0.6.0
    # @api private
    attr_reader :err

    # Invoke the CLI if singular command passed
    #
    # @param arguments [Array<string>] the command line arguments
    # @param out [IO] the standard output (defaults to `$stdout`)
    #
    # @since 0.6.0
    # @api private
    def perform_command(arguments)
      command, args = parse(kommand, arguments, [])
      command.call(**args)
    end

    # Invoke the CLI if registry passed
    #
    # @param arguments [Array<string>] the command line arguments
    # @param out [IO] the standard output (defaults to `$stdout`)
    #
    # @since 0.6.0
    # @api private
    def perform_registry(arguments)
      result = registry.get(arguments)

      if result.found?
        command, args = parse(result.command, result.arguments, result.names)

        result.before_callbacks.run(command, args)
        command.call(**args)
        result.after_callbacks.run(command, args)
      else
        usage(result)
      end
    end

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
    # @since 0.6.0
    # @api private
    def parse(command, arguments, names)
      result = Parser.call(command, arguments, names)

      if result.help?
        out.puts Banner.call(command, names)
        exit(0)
      end

      if result.error?
        err.puts(result.error)
        exit(1)
      end

      [command.new, result.arguments]
    end

    # Prints the command usage and exit.
    #
    # @param result [Dry::CLI::CommandRegistry::LookupResult]
    # @param out [IO] sta output
    #
    # @since 0.1.0
    # @api private
    def usage(result)
      err.puts Usage.call(result)
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

    # Generates registry in runtime
    #
    # @param &block [Block] configuration for the registry
    #
    # @return [Module] module extended with registry abilities and configured with a block
    #
    # @since 0.4.0
    # @api private
    def anonymous_registry(&block)
      registry = Module.new { extend(Dry::CLI::Registry) }
      if block.arity.zero?
        registry.instance_eval(&block)
      else
        yield(registry)
      end
      registry
    end
  end

  # Create a new instance
  #
  # @param registry_or_command [Dry::CLI::Registry, Dry::CLI::Command]
  #   a registry or singular command
  # @param &block [Block] a configuration block for registry
  #
  # @return [Dry::CLI] the new instance
  # @since 0.4.0
  def self.CLI(registry_or_command = nil, &block)
    CLI.new(registry_or_command, &block)
  end
end
