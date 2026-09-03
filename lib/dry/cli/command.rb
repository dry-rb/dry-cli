# frozen_string_literal: true

require "forwardable"
require "dry/cli/option"
require "dry/cli/stream"
require "dry/cli/style_mixin"

module Dry
  class CLI
    # Base class for commands
    #
    # ## Streams
    #
    # A command should write to the streams it is given, available as {#stdout}, {#stderr} and
    # {#stdin}. These are set before `#initialize` runs, so you can access them in your
    # `#initialize` as required.
    #
    # A command registered as an instance (instead of a class) is built before the CLI knows where
    # its output should go, so at that point {#stdout} and {#stderr} fall back to Ruby's standard
    # `$stdout` and `$stderr`. The CLI's real streams arrive later, when the command is called, so
    # you should build on top of streams only when you use them:
    #
    # ```
    # # Wrong: built at initialization; captures the fallback stream
    # def initialize
    #   @logger = Logger.new(stdout)
    # end
    #
    # # Right: built on first use; captures the stream the CLI is using
    # def logger
    #   @logger ||= Logger.new(stdout)
    # end
    # ```
    #
    # @since 0.1.0
    class Command
      include StyleMixin
      extend StyleMixin

      # @since 0.1.0
      # @api private
      def self.inherited(base)
        super
        base.class_eval do
          @_mutex           = Mutex.new
          @description      = nil
          @long_description = nil
          @examples         = []
          @subcommands      = []
          @arguments = base.superclass_arguments || []
          @options = base.superclass_options || []
        end
        base.extend ClassMethods
      end

      # @since 0.1.0
      # @api private
      module ClassMethods
        # @since 0.1.0
        # @api private
        attr_reader :description

        # @api private
        attr_reader :long_description

        # @since 0.1.0
        # @api private
        attr_reader :examples

        # @since 0.1.0
        # @api private
        attr_reader :arguments

        # @since 0.1.0
        # @api private
        attr_reader :options

        # @since 0.7.0
        # @api private
        attr_accessor :subcommands
      end

      # Set the description of the command
      #
      # @param description [String] the description
      #
      # @example
      #   require "dry/cli"
      #
      #   class Echo < Dry::CLI::Command
      #     desc "Prints given input"
      #
      #     def call(*)
      #       # ...
      #     end
      #   end
      #
      # @api public
      # @since 0.1.0
      def self.desc(description)
        @description = description
      end

      # Set the long description of the command
      #
      # It is printed in the "Description" section of the full command help (`--help`). Short help
      # (`-h`) and command listings keep using the short description set via `.desc`. When no long
      # description is set, `--help` falls back to the short description.
      #
      # @param long_description [String] the long description
      #
      # @example
      #   require "dry/cli"
      #
      #   class Echo < Dry::CLI::Command
      #     desc "Prints given input"
      #     long_desc <<~DESC
      #       Prints the given input back to standard output.
      #
      #       When no input is given, it prints an empty line.
      #     DESC
      #
      #     def call(*)
      #       # ...
      #     end
      #   end
      #
      # @api public
      # @since unreleased
      def self.long_desc(long_description)
        @long_description = long_description
      end

      # Describe the usage of the command
      #
      # @param examples [Array<String>] one or more examples
      #
      # @since 0.1.0
      #
      # @example
      #   require "dry/cli"
      #
      #   class Server < Dry::CLI::Command
      #     example "", "Basic usage (it uses the bundled server engine)",
      #     example "--server=webrick, "Force `webrick` server engine",
      #     example "--host=0.0.0.0, "Bind to a host",
      #     example "--port=2306", "Bind to a port",
      #     example "--no-code-reloading", "Disable code reloading"
      #
      #     def call(*)
      #       # ...
      #     end
      #   end
      #
      #   # $ foo server --help
      #   #   # ...
      #   #
      #   #   Examples:
      #   #     foo server                     # Basic usage (it uses the bundled server engine)
      #   #     foo server --server=webrick    # Force `webrick` server engine
      #   #     foo server --host=0.0.0.0      # Bind to a host
      #   #     foo server --port=2306         # Bind to a port
      #   #     foo server --no-code-reloading # Disable code reloading
      def self.example(example, description = "")
        @examples.push([example, description])
      end

      # Specify an argument
      #
      # @param name [Symbol] the argument name
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Optional argument
      #   require "dry/cli"
      #
      #   class Hello < Dry::CLI::Command
      #     argument :name
      #
      #     def call(name: nil, **)
      #       if name.nil?
      #         puts "Hello, stranger"
      #       else
      #         puts "Hello, #{name}"
      #       end
      #     end
      #   end
      #
      #   # $ foo hello
      #   #   Hello, stranger
      #
      #   # $ foo hello Luca
      #   #   Hello, Luca
      #
      # @example Required argument
      #   require "dry/cli"
      #
      #   class Hello < Dry::CLI::Command
      #     argument :name, required: true
      #
      #     def call(name:, **)
      #       puts "Hello, #{name}"
      #     end
      #   end
      #
      #   # $ foo hello Luca
      #   #   Hello, Luca
      #
      #   # $ foo hello
      #   #   ERROR: "foo hello" was called with no arguments
      #   #   Usage: "foo hello NAME"
      #
      # @example Multiple arguments
      #   require "dry/cli"
      #
      #   module Generate
      #     class Action < Dry::CLI::Command
      #       argument :app,    required: true
      #       argument :action, required: true
      #
      #       def call(app:, action:, **)
      #         puts "Generating action: #{action} for app: #{app}"
      #       end
      #     end
      #   end
      #
      #   # $ foo generate action web home
      #   #   Generating action: home for app: web
      #
      #   # $ foo generate action
      #   #   ERROR: "foo generate action" was called with no arguments
      #   #   Usage: "foo generate action APP ACTION"
      #
      # @example Description
      #   require "dry/cli"
      #
      #   class Hello < Dry::CLI::Command
      #     argument :name, desc: "The name of the person to greet"
      #
      #     def call(name: nil, **)
      #       # ...
      #     end
      #   end
      #
      #   # $ foo hello --help
      #   #   Command:
      #   #     foo hello
      #   #
      #   #   Usage:
      #   #     foo hello [NAME]
      #   #
      #   #   Arguments:
      #   #     NAME                # The name of the person to greet
      #   #
      #   #   Options:
      #   #     --help, -h          # Print this help
      def self.argument(name, options = {})
        new_arg = Argument.new(name, options)

        duplicate_index = @arguments.find_index { _1.name == new_arg.name }
        @arguments.delete_at(duplicate_index) unless duplicate_index.nil?

        @arguments << new_arg
      end

      # Command line option (aka optional argument)
      #
      # @param name [Symbol] the param name
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Basic usage
      #   require "dry/cli"
      #
      #   class Console < Dry::CLI::Command
      #     option :engine
      #
      #     def call(engine: nil, **)
      #       puts "starting console (engine: #{engine || :irb})"
      #     end
      #   end
      #
      #   # $ foo console
      #   # starting console (engine: irb)
      #
      #   # $ foo console --engine=pry
      #   # starting console (engine: pry)
      #
      # @example List values
      #   require "dry/cli"
      #
      #   class Console < Dry::CLI::Command
      #     option :engine, values: %w(irb pry ripl)
      #
      #     def call(engine: nil, **)
      #       puts "starting console (engine: #{engine || :irb})"
      #     end
      #   end
      #
      #   # $ foo console
      #   # starting console (engine: irb)
      #
      #   # $ foo console --engine=pry
      #   # starting console (engine: pry)
      #
      #   # $ foo console --engine=foo
      #   # ERROR: Invalid param provided
      #
      # @example Description
      #   require "dry/cli"
      #
      #   class Console < Dry::CLI::Command
      #     option :engine, desc: "Force a console engine"
      #
      #     def call(engine: nil, **)
      #       # ...
      #     end
      #   end
      #
      #   # $ foo console --help
      #   # # ...
      #   #
      #   # Options:
      #   #   --engine=VALUE                  # Force a console engine: (irb, pry, ripl)
      #   #   --help, -h                      # Print this help
      #
      # @example Boolean
      #   require "dry/cli"
      #
      #   class Server < Dry::CLI::Command
      #     option :code_reloading, type: :boolean, default: true
      #
      #     def call(code_reloading:, **)
      #       puts "staring server (code reloading: #{code_reloading})"
      #     end
      #   end
      #
      #   # $ foo server
      #   # starting server (code reloading: true)
      #
      #   # $ foo server --no-code-reloading
      #   # starting server (code reloading: false)
      #
      #   # $ foo server --help
      #   # # ...
      #   #
      #   # Options:
      #   #   --[no]-code-reloading
      #
      # @example Aliases
      #   require "dry/cli"
      #
      #   class Server < Dry::CLI::Command
      #     option :port, aliases: ["-p"]
      #
      #     def call(options)
      #       puts "staring server (port: #{options.fetch(:port, 2300)})"
      #     end
      #   end
      #
      #   # $ foo server
      #   # starting server (port: 2300)
      #
      #   # $ foo server --port=2306
      #   # starting server (port: 2306)
      #
      #   # $ foo server -p 2306
      #   # starting server (port: 2306)
      #
      #   # $ foo server --help
      #   # # ...
      #   #
      #   # Options:
      #   #   --port=VALUE, -p VALUE
      def self.option(name, options = {})
        new_op = Option.new(name, options)

        duplicate_index = @options.find_index { _1.name == new_op.name }
        @options.delete_at(duplicate_index) unless duplicate_index.nil?

        @options << new_op
      end

      # @since 0.1.0
      # @api private
      def self.params
        @_mutex.synchronize do
          (@arguments + @options).uniq
        end
      end

      # @since 0.1.0
      # @api private
      def self.default_params
        params.each_with_object({}) do |param, result|
          result[param.name] = param.default unless param.default.nil?
        end
      end

      # @since 0.1.0
      # @api private
      def self.required_arguments
        arguments.select(&:required?)
      end

      # @since 0.1.0
      # @api private
      def self.optional_arguments
        arguments.reject(&:required?)
      end

      # @since 1.3.0
      # @api private
      # rubocop:disable Metrics/PerceivedComplexity
      def self.arguments_sorted_by_usage_order
        args = required_arguments + optional_arguments

        args.sort! do |a1, a2|
          a1_priority = a2_priority = 0

          a1_priority += 2 unless a1.array?
          a2_priority += 2 unless a2.array?
          a1_priority += 1 if a1.required?
          a2_priority += 1 if a2.required?

          if a1_priority > a2_priority
            -1
          elsif a2_priority > a1_priority
            1
          else
            0
          end
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity

      # @since 0.7.0
      # @api private
      def self.subcommands
        subcommands
      end

      # @since 0.7.0
      # @api private
      def self.superclass_variable_dup(var)
        if superclass.instance_variable_defined?(var)
          superclass.instance_variable_get(var).dup
        end
      end

      # @since 0.7.0
      # @api private
      def self.superclass_arguments
        superclass_variable_dup(:@arguments)
      end

      # @since 0.7.0
      # @api private
      def self.superclass_options
        superclass_variable_dup(:@options)
      end

      # Returns a new command.
      #
      # The command is configured to write to the given streams, which are taken here and set on the
      # command before `#initialize` runs. This allows a subclass to declare its own `#initialize`
      # concerned with only its own arguments, and still use {#stdout}, {#stderr} and {#stdin}
      # inside `#initialize` as needed. All other arguments are passed along untouched.
      #
      # @param stderr [IO, Dry::CLI::Stream, nil] the stream for error output
      # @param stdin [IO, Dry::CLI::Stream, nil] the stream for input
      # @param stdout [IO, Dry::CLI::Stream, nil] the stream for output
      #
      # @return [Dry::CLI::Command]
      #
      # @since x.y.z
      # @api public
      def self.new(*args, stderr: nil, stdin: nil, stdout: nil, **kwargs, &block)
        allocate.tap { |command|
          command.send(:set_streams, stderr:, stdin:, stdout:)
          command.send(:initialize, *args, **kwargs, &block)
        }
      end

      # Returns a copy of this command, configured to write to the given streams.
      #
      # Called on a command registered as an instance, since it is constructed before the CLI is
      # invoked, and therefore before it knows where its output should go.
      #
      # @api private
      def with_streams(stderr:, stdin:, stdout:)
        dup.set_streams(stderr:, stdin:, stdout:)
      end

      extend Forwardable

      delegate %i[
        description
        long_description
        examples
        arguments
        options
        params
        default_params
        required_arguments
        optional_arguments
        arguments_sorted_by_usage_order
        subcommands
      ] => "self.class"

      protected

      # The error output used to print error messaging
      #
      # @return [Dry::CLI::Stream] for the stream given to this command, or `$stderr`
      #
      # @example
      #   class MyCommand
      #     def call
      #       stdout.puts "Hello World!"
      #       exit(0)
      #     rescue StandardError => e
      #       stderr.puts "Uh oh: #{e.message}"
      #       exit(1)
      #     end
      #   end
      #
      # @since x.y.z
      def stderr
        # When we haven't been given an underlying stream, build a new one for $stderr each time,
        # since it can be swapped out from under us. This is the case only when testing commands in
        # isolation; when the CLI runs normally, we have a real @stderr set.
        return Stream.for($stderr) unless @stderr

        @stderr_stream ||= Stream.for(@stderr)
      end

      # The standard input stream used for reading input
      #
      # @return [IO] the stream given to this command, or `$stdin`
      #
      # @example
      #   class MyCommand
      #     def call
      #       name = stdin.gets.chomp
      #       stdout.puts "Hello #{name}!"
      #     end
      #   end
      #
      # @since x.y.z
      def stdin
        @stdin || $stdin
      end

      # The standard output stream used for normal output
      #
      # @return [Dry::CLI::Stream] for the stream given to this command, or `$stdout`
      #
      # @example
      #   class MyCommand
      #     def call
      #       stdout.puts "Hello World!"
      #     end
      #   end
      #
      # @since x.y.z
      def stdout
        # When we haven't been given an underlying stream, build a new one for $stdout each time,
        # since it can be swapped out from under us. This is the case only when testing commands in
        # isolation; when the CLI runs normally, we have a real @stdout set.
        return Stream.for($stdout) unless @stdout

        @stdout_stream ||= Stream.for(@stdout)
      end

      # @see #with_streams
      #
      # @api private
      def set_streams(stderr:, stdin:, stdout:)
        @stderr = stderr
        @stdin = stdin
        @stdout = stdout
        @stderr_stream = nil
        @stdout_stream = nil

        self
      end

      private

      # Writes to the command's own {#stdout}, rather than the default `$stdout`.
      #
      # Commands are given the streams they write to, so `puts` inside one goes to the stream this
      # command was given, not to `$stdout`. That's what keeps styling right when the two differ:
      # text written here is styled for the stream it lands on.
      #
      # @example
      #   class MyCommand
      #     def call
      #       puts "Hello World!"
      #     end
      #   end
      #
      # @since x.y.z
      def puts(*args)
        stdout.puts(*args)
      end

      # Writes to the command's own {#stdout}, rather than the default `$stdout`.
      #
      # @see #puts
      #
      # @since x.y.z
      def print(*args)
        stdout.print(*args)
      end
    end
  end
end
