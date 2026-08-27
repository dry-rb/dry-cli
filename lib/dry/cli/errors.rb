# frozen_string_literal: true

module Dry
  # General purpose Command Line Interface (CLI) framework for Ruby
  #
  # @since 0.1.0
  class CLI
    # @since 0.2.0
    class Error < StandardError
    end

    # @since 1.5.0
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

    # British spelling of {InvalidColorError}. The two names are the same class, so rescuing
    # either catches both.
    #
    # @since 1.5.0
    InvalidColourError = InvalidColorError

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
          accepted = @argument.values
          "ERROR: invalid argument \"#{@value}\" for \"#{@argument.name}\"; accepted values: #{accepted.join(', ')}"
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
