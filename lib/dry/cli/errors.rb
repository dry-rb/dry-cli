# frozen_string_literal: true

module Dry
  # General purpose Command Line Interface (CLI) framework for Ruby
  #
  # @since 0.1.0
  class CLI
    # @since 0.2.0
    class Error < StandardError
    end

    # Raise from a command or callback to stop the CLI with a message for the user.
    #
    # The CLI prints the message (with no backtrace) to its stderr, then exits with {#exit_code}.
    # Subclass this for your own user-facing errors.
    #
    # Use this for problems the user should know about and might be able to address, such as a
    # missing file or a failed subprocess. Do not use it for bugs. Other errors are not rescued, so
    # they keep their backtrace.
    #
    # This is a `StandardError`, so a broad `rescue` (such as `rescue => e`) between the raise and
    # the CLI will catch it, and the CLI will not see it. To stop in a way that no `rescue` can catch,
    # use `throw :exit` instead.
    #
    # @example
    #   raise Dry::CLI::ExitError, "config.yml not found"
    #   raise Dry::CLI::ExitError.new("deploy failed", exit_code: 2)
    #
    # @api public
    # @since 2.0.0
    class ExitError < Error
      # @param message [String] the message to print to stderr
      # @param exit_code [Integer] the code to exit with (defaults to 1)
      #
      # @api public
      # @since 2.0.0
      def initialize(message, exit_code: 1)
        super(message)
        @exit_code = exit_code
      end

      # Returns the code the CLI exits with.
      #
      # This is 1 when no code is set, such as when a subclass gives `exit_code: nil` or does not
      # call `super` in its `#initialize`. This way, a missing code never makes an error exit with 0.
      #
      # @return [Integer]
      #
      # @api public
      # @since 2.0.0
      def exit_code = @exit_code || 1
    end

    # @api public
    # @since x.y.z
    class InvalidColorError < Error
      attr_reader :value, :expected

      def initialize(value:, expected:)
        @value = value
        @expected = expected
        super()
      end

      def message
        "ERROR: invalid color #{@value.inspect}; expected #{@expected}"
      end
    end

    # @since 1.4.0
    class ValueError < Error
      attr_reader :value, :argument

      def initialize(value: nil, argument: nil)
        @value = value
        @argument = argument
        super
      end

      def message
        if @value.nil? && @argument
          "ERROR: \"#{@argument.name}\" is required"
        elsif @argument
          "ERROR: invalid argument \"#{@value}\" for \"#{@argument.name}\"; " \
            "accepted values: #{@argument.values_description}"
        else
          "ERROR: invalid argument \"#{@value}\""
        end
      end
    end

    # @since NEXT
    class CastError < Error
      def initialize(arg_name:, original_exception: nil)
        super
        @arg_name = arg_name
        @original_exception = original_exception
      end

      def message
        msg = "ERROR when casting #{@arg_name}"
        if @original_exception
          msg += ": #{@original_exception.message}."
        end
        msg
      end
    end

    # @since 0.2.1
    class UnknownCommandError < Error
      # @since 0.2.1
      # @api private
      def initialize(command_name)
        super("unknown command: `#{command_name}'")
      end
    end

    # Raised when a command is defined incorrectly, such as:
    #
    # - a required argument declared after an optional one
    # - an argument declared after an array argument
    # - an argument declared with both `required: true` and a `default:`
    # - an option added to a command that already declares one with the same name, but with
    #   different settings
    #
    # @api public
    # @since 2.0.0
    class CommandDefinitionError < Error
    end

    # @since 0.2.0
    class InvalidCallbackError < Error
      # @since 0.2.0
      # @api private
      def initialize(callback)
        message = case callback
                  when Class
                    "expected `#{callback.inspect}' to respond to `#initialize' with arity 0"
                  else
                    "expected `#{callback.inspect}' to respond to `#call'"
                  end

        super(message)
      end
    end
  end
end
