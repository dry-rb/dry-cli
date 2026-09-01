# frozen_string_literal: true

module Dry
  # General purpose Command Line Interface (CLI) framework for Ruby
  #
  # @since 0.1.0
  class CLI
    # @since 0.2.0
    class Error < StandardError
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

    # Raised when an option is added to a command that already declares one with the same name,
    # but with an incompatible declaration.
    #
    # Adding the very same option twice is allowed, so that independent third-party gems can each
    # contribute the option they need without having to coordinate.
    #
    # @api public
    # @since NEXT
    class IncompatibleOptionError < Error
      # @api private
      def initialize(command_name, name, incompatible_option_names)
        super("`#{name}' is already declared for command `#{command_name}' " \
              "with a different #{incompatible_option_names.join(", ")}")
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
