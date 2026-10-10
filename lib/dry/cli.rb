# frozen_string_literal: true

# Dry
#
# @since 0.1.0
module Dry
  # General purpose Command Line Interface (CLI) framework for Ruby
  #
  # @since 0.1.0
  class CLI
    require "dry/cli/version"
    require "dry/cli/errors"
    require "dry/cli/namespace"
    require "dry/cli/ansi"
    require "dry/cli/style"
    require "dry/cli/stream"
    require "dry/cli/style_mixin"
    require "dry/cli/command"
    require "dry/cli/registry"
    require "dry/cli/parser"
    require "dry/cli/usage"
    require "dry/cli/spell_checker"
    require "dry/cli/banner"
    require "dry/cli/screen"
    require "dry/cli/config"
    require "dry/cli/inflector"
    require "dry/cli/dispatch"
    require "dry/cli/launcher"

    # Stops the CLI with an exit status.
    #
    # Raised where the CLI has printed help or an error, and rescued by {#call}, which hands the
    # status to the kernel. Stopping by raising means that a kernel whose `exit` returns, such as
    # the one Aruba uses to run a CLI in-process, still stops the CLI at that point.
    #
    # @api private
    class Halt < StandardError
      # @return [Integer] the exit status
      attr_reader :status

      # @param status [Integer] the exit status
      def initialize(status)
        super("exit #{status}")
        @status = status
      end
    end
    private_constant :Halt

    autoload :Spinner, "dry/cli/spinner"

    # Check if command
    #
    # @param command [Object] the command to check
    #
    # @return [Boolean] true if instance of `Dry::CLI::Command`
    #
    # @since 0.1.0
    # @api private
    def self.command?(command)
      inherits?(command, Command)
    end

    # Check if namespace
    #
    # @param namespace [Object] the namespace to check
    #
    # @return [Boolean] true if instance of `Dry::CLI::Namespace`
    #
    # @since 1.1.1
    # @api private
    def self.namespace?(namespace)
      inherits?(namespace, Namespace)
    end

    # Check if `obj` inherits from `klass`
    #
    # @param obj [Object] object to check
    # @param klass [Object] class that should be inherited
    #
    # @return [Boolean] true if `obj` inherits from `klass`
    #
    # @since 1.1.1
    # @api private
    def self.inherits?(obj, klass)
      case obj
      when Class
        obj.ancestors.include?(klass)
      else
        obj.is_a?(klass)
      end
    end

    # Create a new instance
    #
    # @param command_or_registry [Dry::CLI::Registry, Dry::CLI::Command]
    #   a registry or singular command
    # @param config [Dry::CLI::Config, nil] settings for this CLI, in place of the process-wide
    #   {.config}
    # @param &block [Block] a configuration block for registry
    #
    # @return [Dry::CLI] the new instance
    # @since 0.1.0
    def initialize(command_or_registry = nil, config: nil, &block)
      @kommand = command_or_registry if command?(command_or_registry)
      @config = config

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
    # @param stderr [IO] the error output (defaults to `$stderr`)
    # @param stdin [IO] the standard input (defaults to `$stdin`)
    # @param stdout [IO] the standard output (defaults to `$stdout`)
    # @param kernel [#exit] what the CLI and its commands exit through (defaults to `Kernel`).
    #   Only an exit is ever sent to it, so a test can pass an object that records the status
    #   instead of ending the process. See {Dry::CLI::Launcher}.
    #
    # @since 0.1.0
    def call(arguments: ARGV, stderr: $stderr, stdin: $stdin, stdout: $stdout, kernel: Kernel)
      @stderr, @stdin, @stdout = Stream.for(stderr), stdin, Stream.for(stdout)
      @kernel = kernel
      @arguments = arguments
      kommand ? perform_command(arguments) : perform_registry(arguments)
    rescue Halt => exception
      kernel.exit(exception.status)
    rescue SignalException => exception
      signal_exception(exception)
    rescue Errno::EPIPE
      # no op
    end

    # Returns a read-only view of the commands this CLI runs.
    #
    # @return [Dry::CLI::Tree::Node] the root: the command itself for a single-command CLI, and
    #   otherwise a node whose children are the top-level commands
    #
    # @since x.y.z
    #
    # @see Dry::CLI::Tree
    def tree
      kommand ? Tree.for(kommand) : registry.tree
    end

    private

    # @since 0.6.0
    # @api private
    attr_reader :registry

    # @since 0.6.0
    # @api private
    attr_reader :kommand

    # @api private
    attr_reader :stderr

    # @api private
    attr_reader :stdin

    # @api private
    attr_reader :stdout

    # @api private
    attr_reader :kernel

    # @api private
    attr_reader :arguments

    # The settings this CLI reads: its own, or the process-wide ones.
    #
    # @return [Dry::CLI::Config]
    #
    # @api private
    def config
      @config || CLI.config
    end

    # Invoke the CLI if singular command passed
    #
    # @param arguments [Array<string>] the command line arguments
    # @param out [IO] the standard output (defaults to `$stdout`)
    #
    # @since 0.6.0
    # @api private
    def perform_command(arguments)
      command, args = parse(kommand, arguments, [])
      command.call(**Dispatch.command_args_for(command, args))
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
      return spell_checker(result, arguments) unless result.found?

      command, args = parse(result.command, result.arguments, result.names)
      unless command.respond_to?(:call)
        return show(
          kind: :listing, reason: :no_command, node: tree.dig(*result.names),
          prog_name: ProgramName.call(result.names), status: nil
        )
      end

      result.before_callbacks.run(command, **args)
      command.call(**Dispatch.command_args_for(command, args))
      result.after_callbacks.run(command, **args)
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
      prog_name = ProgramName.call(names)

      result = Parser.call(command, arguments, prog_name)

      return help(names, prog_name, long: result.long_help?) if result.help?

      return error(result) if result.error?

      [build_command(command), result.arguments]
    end

    # @since 0.6.0
    # @api private
    def build_command(command)
      unless command.is_a?(Class)
        return command unless command.is_a?(Command)

        return command.with_streams(stderr:, stdin:, stdout:, kernel:)
      end

      return command.new(stderr:, stdin:, stdout:, kernel:) if CLI.command?(command)

      command.new
    end

    # @since 0.6.0
    # @api private
    def help(names, prog_name, long: false)
      show(kind: :command, reason: :help, node: tree.dig(*names), prog_name:, long:, status: 0)
    end

    # @since 0.6.0
    # @api private
    def error(result)
      stderr.puts(result.error)
      halt(1)
    end

    # @since 1.1.1
    def spell_checker(result, arguments)
      unmatched = arguments.drop(result.names.length)

      show(
        kind: :listing, reason: listing_reason(unmatched), node: tree.dig(*result.names),
        prog_name: ProgramName.call(result.names), long: unmatched.first == "--help",
        suggestion: SpellChecker.call(result, arguments), status: 1
      )
    end

    # Help flags, which name no command when given where a command is expected.
    #
    # @api private
    HELP_FLAGS = %w[-h --help].freeze
    private_constant :HELP_FLAGS

    # Why a listing is shown, given the arguments after the last one that named a command.
    #
    # @param unmatched [Array<String>]
    #
    # @return [Symbol] `:no_command`, `:help` or `:unknown`
    #
    # @api private
    def listing_reason(unmatched)
      if unmatched.empty? then :no_command
      elsif HELP_FLAGS.include?(unmatched.first) then :help
      else :unknown
      end
    end

    # Renders a help screen through the configured renderer and filters, prints it, and stops the
    # CLI with its status, unless that is nil.
    #
    # @param fields [Hash] the fields of the {Screen}, other than those every screen shares
    #
    # @api private
    def show(long: false, suggestion: nil, **fields)
      screen = config.help.call(
        Screen.new(long:, suggestion:, arguments:, text: nil, stdout:, stderr:, **fields)
      )

      screen.io.puts(screen.text)
      halt(screen.status) unless screen.status.nil?
    end

    # Stops the CLI, which {#call} turns into an exit through the kernel.
    #
    # @param status [Integer] the exit status
    #
    # @raise [Halt] always
    #
    # @api private
    def halt(status)
      raise Halt, status
    end

    # Handles Exit codes for signals
    # Fatal error signal "n". Say 130 = 128 + 2 (SIGINT) or 137 = 128 + 9 (SIGKILL)
    #
    # @since 0.7.0
    # @api private
    def signal_exception(exception)
      kernel.exit(128 + exception.signo)
    end

    # Check if command
    #
    # @param command [Object] the command to check
    #
    # @return [Boolean] true if instance of `Dry::CLI::Command`
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
  # @param config [Dry::CLI::Config, nil] settings for this CLI, in place of the process-wide
  #   {Dry::CLI.config}
  # @param &block [Block] a configuration block for registry
  #
  # @return [Dry::CLI] the new instance
  # @since 0.4.0
  def self.CLI(registry_or_command = nil, config: nil, &block)
    CLI.new(registry_or_command, config:, &block)
  end
end
