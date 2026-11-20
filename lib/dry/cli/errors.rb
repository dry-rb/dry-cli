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
        "invalid color #{@value.inspect}; expected #{@expected}"
      end
    end

    # Raised when the user gives a value that isn't among an option's or argument's accepted
    # `values:`.
    #
    # @since 1.4.0
    class ValueError < Error
      # @return [String, Array<String>, nil] the invalid value, or the invalid values given to an
      #   array option or argument
      attr_reader :value

      # @return [Dry::CLI::Option, Dry::CLI::Argument, nil] the option or argument that was given
      #   the value
      attr_reader :argument

      def initialize(value: nil, argument: nil)
        @value = value
        @argument = argument
        super()
      end

      # Returns the message for the user, such as:
      #
      #   invalid value "slow" for --mode; accepted values: fast, safe
      #
      # The CLI prints it after an `Error:` label.
      def message
        return "missing required #{@argument.kind} #{@argument.display_name}" if @value.nil? && @argument

        values = Array(@value)
        msg = "#{values.one? ? "invalid value" : "invalid values"} #{values.map { %("#{_1}") }.join(", ")}"
        msg += " for #{@argument.display_name}" if @argument
        msg += "; accepted values: #{@argument.values_description}" if @argument&.values
        msg
      end
    end

    # Raised when an option's or argument's `cast:` raises an error for a value the user gave.
    #
    # @since 2.0.0
    class CastError < Error
      # @return [String] the value that could not be cast
      attr_reader :value

      # @return [Dry::CLI::Option, Dry::CLI::Argument] the option or argument that was given the
      #   value
      attr_reader :argument

      # @return [Exception, nil] the error raised by the `cast:`
      attr_reader :original_exception

      def initialize(value:, argument:, original_exception: nil)
        @value = value
        @argument = argument
        @original_exception = original_exception
        super()
      end

      # Returns the message for the user, such as:
      #
      #   invalid value "abc" for --port: invalid value for Integer(): "abc"
      #
      # The CLI prints it after an `Error:` label.
      def message
        msg = %(invalid value "#{@value}" for #{@argument.display_name})
        msg += ": #{@original_exception.message}" if @original_exception
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
