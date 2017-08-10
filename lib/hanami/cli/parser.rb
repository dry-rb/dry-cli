require "optparse"
require "hanami/cli/program_name"

module Hanami
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
      # rubocop:disable Metrics/MethodLength
      def self.call(command, arguments, names)
        parsed_options = {}

        OptionParser.new do |opts|
          command.options.each do |option|
            opts.on(*option.parser_options) do |value|
              parsed_options[option.name.to_sym] = value
            end
          end

          opts.on_tail("-h", "--help") do
            return Result.help
          end
        end.parse!(arguments.dup)

        parsed_options = command.default_params.merge(parsed_options)
        parse_required_params(command, arguments, names, parsed_options)
      rescue ::OptionParser::ParseError
        return Result.failure
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # @since 0.1.0
      # @api private
      def self.full_command_name(names)
        ProgramName.call(names)
      end

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def self.parse_required_params(command, arguments, names, parsed_options)
        parse_params = Hash[command.arguments.map(&:name).zip(arguments)]
        parse_required_params = Hash[command.required_arguments.map(&:name).zip(arguments)]
        all_required_params_satisfied = command.required_arguments.all? { |param| !parse_required_params[param.name].nil? }

        unless all_required_params_satisfied
          parse_required_params_values = parse_required_params.values.compact

          usage = "\nUsage: \"#{full_command_name(names)} #{command.required_arguments.map(&:description_name).join(' ')}\""

          if parse_required_params_values.empty? # rubocop:disable Style/GuardClause
            return Result.failure("ERROR: \"#{full_command_name(names)}\" was called with no arguments#{usage}")
          else
            return Result.failure("ERROR: \"#{full_command_name(names)}\" was called with arguments #{parse_required_params_values}#{usage}")
          end
        end

        Result.success(parse_params.merge(parsed_options))
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

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
