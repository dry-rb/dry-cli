# frozen_string_literal: true

require "delegate"

module Dry
  class CLI
    # Runs a CLI from its executable, or in-process from a test.
    #
    # A launcher takes everything the CLI talks to (the arguments, the three standard streams, and
    # the kernel it exits through) as arguments, in the order Aruba's in-process launcher passes
    # them. Tests can then run the CLI in the same process as the test, with a StringIO for each
    # stream, and an object that records the exit status in place of `Kernel`.
    #
    # Bind a launcher to your registry, or to a single command, with {.[]}.
    #
    # @example The launcher, and the executable that uses it
    #   # lib/my_app/launcher.rb
    #   module MyApp
    #     Launcher = Dry::CLI::Launcher[MyApp::Commands]
    #   end
    #
    #   # exe/my_app
    #   MyApp::Launcher.new(ARGV).execute!
    #
    # @example Running it in-process with Aruba
    #   Aruba.configure do |config|
    #     config.command_launcher = :in_process
    #     config.main_class       = MyApp::Launcher
    #   end
    #
    # @api public
    # @since x.y.z
    class Launcher
      # What each parameter of {#initialize} after `argv` falls back to, read when a launcher is
      # created rather than when this file is loaded.
      #
      # @api private
      GLOBALS = {
        stdin: -> { $stdin },
        stdout: -> { $stdout },
        stderr: -> { $stderr },
        kernel: -> { Kernel }
      }.freeze

      class << self
        # Returns a launcher for the given registry or command.
        #
        # Each keyword pins the default for its parameter of {#initialize}, for when the executable
        # passes only `argv`. A launcher called with all five arguments, as Aruba does, uses those
        # instead. A parameter without a pinned default takes its global (`$stdin`, `$stdout`,
        # `$stderr` or `Kernel`) at the time the launcher is created, not at the time this method
        # is called.
        #
        # @param target [Dry::CLI::Registry, Dry::CLI::Command] what to run
        # @param stdin [IO, nil] the default input
        # @param stdout [IO, nil] the default output
        # @param stderr [IO, nil] the default error output
        # @param kernel [#exit, nil] the default kernel
        #
        # @return [Class] a subclass of {Launcher} bound to `target`
        #
        # @example
        #   Launcher = Dry::CLI::Launcher[MyApp::Commands, stdout: SyncedStdout.new]
        #
        # @api public
        # @since x.y.z
        def [](target, stdin: nil, stdout: nil, stderr: nil, kernel: nil)
          defaults = {stdin:, stdout:, stderr:, kernel:}.compact.freeze

          Class.new(self) do
            @target = target
            @defaults = defaults
          end
        end

        # @return [Dry::CLI::Registry, Dry::CLI::Command, nil] what this launcher runs
        #
        # @api private
        attr_reader :target

        # @return [Hash{Symbol => Object}] the defaults pinned by {.[]}
        #
        # @api private
        def defaults
          @defaults || {}
        end
      end

      # @return [Array<String>] the command line arguments
      #
      # @api public
      attr_reader :argv

      # @return [IO] the input
      #
      # @api public
      attr_reader :stdin

      # @return [IO] the output
      #
      # @api public
      attr_reader :stdout

      # @return [IO] the error output
      #
      # @api public
      attr_reader :stderr

      # @return [#exit] what the CLI exits through
      #
      # @api public
      attr_reader :kernel

      # @param argv [Array<String>] the command line arguments
      # @param stdin [IO, nil] the input, or nil for the default
      # @param stdout [IO, nil] the output, or nil for the default
      # @param stderr [IO, nil] the error output, or nil for the default
      # @param kernel [#exit, nil] what to exit through, or nil for the default
      #
      # @api public
      # @since x.y.z
      def initialize(argv = ARGV, stdin = nil, stdout = nil, stderr = nil, kernel = nil)
        given = {stdin:, stdout:, stderr:, kernel:}.compact
        values = GLOBALS.transform_values(&:call).merge(self.class.defaults, given)

        @argv = argv
        @stdin = values.fetch(:stdin)
        @stdout = values.fetch(:stdout)
        @stderr = values.fetch(:stderr)
        @kernel = values.fetch(:kernel)
      end

      # Runs the CLI, then exits with a status of 0 unless the CLI or a command exited already.
      #
      # Exceptions raised by a command are not rescued, so a test running the CLI in-process sees
      # the original error and its backtrace.
      #
      # @raise [ArgumentError] if the launcher was not bound with {.[]}
      #
      # @api public
      # @since x.y.z
      def execute!
        target = self.class.target or
          raise ArgumentError, "no CLI to launch: bind one with Dry::CLI::Launcher[MyApp::Commands]"

        exits = ExitTracker.new(kernel)
        Dry.CLI(target).call(arguments: argv, stdin:, stdout:, stderr:, kernel: exits)
        kernel.exit(0) unless exits.exited?
      end

      # Passes everything through to a kernel, noting whether `exit` was called.
      #
      # A kernel used for testing records the status and returns, so without this, the launcher's
      # final exit would overwrite a status the CLI had already set.
      #
      # @api private
      class ExitTracker < SimpleDelegator
        # @param status [Boolean, Integer] the exit status
        #
        # @return [Object] whatever the kernel returns, when it returns at all
        def exit(status)
          @exited = true
          __getobj__.exit(status)
        end

        # @return [Boolean] whether `exit` was called
        def exited?
          @exited == true
        end
      end
      private_constant :ExitTracker
    end
  end
end
