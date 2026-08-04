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
      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize
      def self.call(command, arguments, prog_name)
        parsed_options = {}

        OptionParser.new do |opts|
          command.options.each do |option|
            opts.on(*option.parser_options) do |value|
              raise ValueError.new(value: value, argument: option) unless option.valid_value?(value)

              option_name = option.name.to_sym
              if option.array?
                parsed_options[option_name] ||= []
                parsed_options[option_name] += option.cast(value)
              else
                parsed_options[option_name] = option.cast(value)
              end
            end
          end

          opts.on_tail("-h", "--help") do
            return Result.help
          end
        end.parse!(arguments)

        parsed_options = command.default_params.merge(parsed_options)
        parse_required_params(command, arguments, prog_name, parsed_options)
      rescue ::OptionParser::ParseError => exception
        Result.failure("ERROR: \"#{prog_name}\" was called with #{exception.reason} \"#{exception.args.join(" ")}\"")
      rescue ValueError => exception
        Result.failure(exception.message)
      rescue CastError => exception
        Result.failure(exception.message)
      end
      # rubocop:enable Metrics/AbcSize

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Layout/LineLength
      def self.parse_required_params(command, arguments, prog_name, parsed_options)
        parsed_params = match_arguments(command.arguments, arguments, parsed_options)
        parsed_required_params = match_arguments(command.required_arguments, arguments, parsed_options)
        all_required_params_satisfied = command.required_arguments.all? { |param| !parsed_required_params[param.name].nil? }

        unused_arguments = arguments.drop(command.required_arguments.length)

        unless all_required_params_satisfied
          # Drop nils as well as empty arrays; an array argument that consumed nothing was not
          # given, so it shouldn't be listed among the arguments that were.
          parsed_required_params_values = parsed_required_params.values.compact.reject { |v| v.is_a?(Array) && v.empty? }

          usage = "\nUsage: \"#{prog_name} #{command.required_arguments.map(&:description_name).join(" ")}"

          usage += " | #{prog_name} SUBCOMMAND" if command.subcommands.any?

          usage += '"'

          if parsed_required_params_values.empty?
            return Result.failure("ERROR: \"#{prog_name}\" was called with no arguments#{usage}")
          else
            return Result.failure("ERROR: \"#{prog_name}\" was called with arguments #{parsed_required_params_values}#{usage}")
          end
        end

        parsed_params.reject! { |_key, value| value.nil? }
        parsed_options = parsed_options.merge(parsed_params)
        parsed_options = parsed_options.merge(args: unused_arguments) if unused_arguments.any?
        Result.success(parsed_options)
      end
      # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Layout/LineLength

      # rubocop:disable Metrics/PerceivedComplexity
      def self.match_arguments(command_arguments, arguments, default_values)
        result = {}

        command_arguments.each_with_index do |cmd_arg, index|
          value =
            if cmd_arg.array?
              # An array argument consumes all the remaining arguments, so it's always the last.
              # The slice is nil when the command declares more arguments than were given.
              arguments[index..] || default_values[cmd_arg.name] || []
            else
              arguments.at(index) || default_values[cmd_arg.name]
            end

          raise ValueError.new(value: value, argument: cmd_arg) unless cmd_arg.valid_value?(value)

          result[cmd_arg.name] = cmd_arg.cast(value)

          break if cmd_arg.array?
        end

        result
      end
      # rubocop:enable Metrics/PerceivedComplexity

      # @since 0.1.0
      # @api private
      class Result
        # @since 0.1.0
        # @api private
        def self.help
          new(help: true)
        end

        # @since 0.1.0
        # @api private
        def self.success(arguments = {})
          new(arguments: arguments)
        end

        # @since 0.1.0
        # @api private
        def self.failure(error = "Error: Invalid param provided")
          new(error: error)
        end

        # @since 0.1.0
        # @api private
        attr_reader :arguments

        # @since 0.1.0
        # @api private
        attr_reader :error

        # @since 0.1.0
        # @api private
        def initialize(arguments: {}, error: nil, help: false)
          @arguments = arguments
          @error     = error
          @help      = help
        end

        # @since 0.1.0
        # @api private
        def error?
          !error.nil?
        end

        # @since 0.1.0
        # @api private
        def help?
          @help
        end
      end
    end
  end
end
