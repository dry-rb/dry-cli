# frozen_string_literal: true

require "optparse"
require "dry/cli/program_name"

module Dry
  class CLI
    # Parse command line arguments and options
    #
    # @since 0.1.0
    # @api private
    module Parser
      # Whether OptionParser's `require_exact` works correctly.
      #
      # Before optparse 0.5.0 (which ships with Ruby 3.4), `require_exact` also rejects exact
      # options given with a value (`--token=x`) or negated (`--no-verbose`). On those versions, we
      # accept abbreviations instead.
      #
      # @api private
      EXACT_OPTIONS = Gem::Version.new(OptionParser::Version) >= Gem::Version.new("0.5.0")

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize
      def self.call(command, arguments)
        parsed_options = {}

        OptionParser.new do |opts|
          # Don't accept abbreviations like `--verb` for `--verbose`. Adding an option could make an
          # abbreviation ambiguous, and break scripts that rely on it.
          opts.require_exact = true if EXACT_OPTIONS

          command.options.each do |option|
            opts.on(*option.parser_options) do |value|
              check_values(option, value)

              option_name = option.name.to_sym
              if option.array?
                parsed_options[option_name] ||= []
                parsed_options[option_name] += option.cast(value)
              else
                parsed_options[option_name] = option.cast(value)
              end
            end
          end

          opts.on_tail("-h") do
            return Result.help
          end

          opts.on_tail("--help") do
            return Result.help(long: true)
          end
        end.parse!(arguments)

        parse_required_params(command, arguments, parsed_options)
      rescue ::OptionParser::ParseError => exception
        Result.failure(option_parser_error_message(exception))
      rescue ValueError, CastError => exception
        Result.failure(exception.message)
      end
      # rubocop:enable Metrics/AbcSize

      # Raises a {ValueError} naming the values that aren't among the accepted `values:` of the
      # given option or argument, if any.
      #
      # @api private
      def self.check_values(option, value)
        invalid_values = option.invalid_values(value)
        return if invalid_values.empty?

        raise ValueError.new(value: option.array? ? invalid_values : invalid_values.first, argument: option)
      end

      # Returns a message for an error from OptionParser, in our own words.
      #
      # The exception's first arg is the option as the user typed it, such as `--token` or
      # `--verbose=yes`.
      #
      # @api private
      def self.option_parser_error_message(exception)
        flag, value = exception.args.first.to_s.split("=", 2)
        value = exception.args[1] if value.nil?

        case exception
        when ::OptionParser::InvalidOption
          "unknown option #{flag}"
        when ::OptionParser::MissingArgument
          "option #{flag} needs a value"
        when ::OptionParser::NeedlessArgument
          "option #{flag} doesn't take a value"
        when ::OptionParser::InvalidArgument
          %(invalid value "#{value}" for #{flag})
        when ::OptionParser::AmbiguousOption
          # Only raised when we accept abbreviations (see {EXACT_OPTIONS})
          "ambiguous option #{flag}"
        else
          exception.message
        end
      end

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize
      def self.parse_required_params(command, arguments, parsed_options)
        parsed_options_with_defaults = command.default_params.merge(parsed_options)
        parsed_params = match_arguments(command.arguments, arguments, parsed_options_with_defaults)
        parsed_required_params = match_arguments(command.required_arguments, arguments, parsed_options_with_defaults)

        missing_arguments = command.required_arguments.select { missing_value?(_1, parsed_required_params[_1.name]) }
        missing_options = command.required_options.select { |option| parsed_options_with_defaults[option.name].nil? }

        args = unused_arguments(command, arguments)

        if missing_arguments.any? || missing_options.any?
          return missing_params_failure(missing_arguments, missing_options)
        end

        parsed_params.reject! { |_key, value| value.nil? }
        parsed_options = parsed_options_with_defaults.merge(parsed_params)
        parsed_options = parsed_options.merge(args:) if args.any?
        Result.success(parsed_options)
      end
      # rubocop:enable Metrics/AbcSize

      # Returns true if the given value for a required argument means the user didn't give it.
      #
      # An array argument gets an empty array when no values are given.
      #
      # @api private
      def self.missing_value?(argument, value)
        value.nil? || (argument.array? && value.empty?)
      end

      # Returns the short usage line printed after an input error, such as:
      #
      #   Usage: foo copy SRC DEST [MODE] --token=VALUE
      #
      # It shows all the arguments, with optional ones in brackets, but only the required options.
      #
      # @api private
      def self.short_usage(command, prog_name)
        usage = [
          prog_name,
          *command.arguments_sorted_by_usage_order.map(&:usage_name),
          *command.required_options.map { |option| Banner.option_usage(option) }
        ].join(" ")
        usage += " | #{prog_name} SUBCOMMAND" if command.subcommands.any?

        "Usage: #{usage}"
      end

      # Returns a failure with one message for the missing arguments and one for the missing
      # options, such as:
      #
      #   missing required arguments SRC, DEST
      #   missing required option --token
      #
      # @api private
      def self.missing_params_failure(missing_arguments, missing_options)
        messages = [missing_arguments, missing_options].reject(&:empty?).map { |params|
          kind = params.first.kind
          label = params.one? ? "required #{kind}" : "required #{kind}s"

          "missing #{label} #{params.map(&:display_name).join(", ")}"
        }

        Result.failure(*messages)
      end

      # Returns the values given after the declared arguments, which are passed to the command as
      # `args`.
      #
      # An array argument takes all the remaining values, so it leaves none.
      #
      # @api private
      def self.unused_arguments(command, arguments)
        return [] if command.arguments.any?(&:array?)

        arguments.drop(command.arguments.length)
      end

      def self.match_arguments(command_arguments, arguments, default_values)
        result = {}

        command_arguments.each_with_index do |cmd_arg, index|
          value =
            if cmd_arg.array?
              # An array argument consumes all the remaining arguments, so it's always the last.
              given = arguments.drop(index)
              given.empty? ? default_values[cmd_arg.name] || [] : given
            else
              arguments.at(index) || default_values[cmd_arg.name]
            end

          check_values(cmd_arg, value)

          result[cmd_arg.name] = cmd_arg.cast(value)

          break if cmd_arg.array?
        end

        result
      end

      # @since 0.1.0
      # @api private
      class Result
        # @since 0.1.0
        # @api private
        def self.help(long: false)
          new(help: true, long_help: long)
        end

        # @since 0.1.0
        # @api private
        def self.success(arguments = {})
          new(arguments: arguments)
        end

        # Returns a failure with one or more messages for the user. Each message says what's wrong,
        # with no `Error:` label.
        #
        # @since 0.1.0
        # @api private
        def self.failure(*errors)
          new(errors:)
        end

        # @since 0.1.0
        # @api private
        attr_reader :arguments

        # @api private
        attr_reader :errors

        # @since 0.1.0
        # @api private
        def initialize(arguments: {}, errors: [], help: false, long_help: false)
          @arguments = arguments
          @errors    = errors
          @help      = help
          @long_help = long_help
        end

        # @since 0.1.0
        # @api private
        def error?
          errors.any?
        end

        # @since 0.1.0
        # @api private
        def help?
          @help
        end

        # @api private
        def long_help?
          @long_help
        end
      end
    end
  end
end
