require "optparse"
require "hanami/cli/program_name"

module Hanami
  class Cli
    module Parser
      def self.call(command, arguments, names, out)
        parsed_options = {}

        OptionParser.new do |opts|
          opts.banner = "Usage:"
          opts.separator("  #{full_command_name(names)}")
          opts.separator("")

          if command.description
            opts.separator("Description:")
            opts.separator("  #{command.description}")
            opts.separator("")
          end

          opts.separator("Options:")

          command.params.each do |param|
            next if param.required?
            opts.on(*param.parser_options) do |value|
              parsed_options[param.name.to_sym] = value
            end
          end

          opts.on_tail("-h", "--help", "Show this message") do
            out.puts opts
            return Result.help
          end
        end.parse!(arguments.dup)

        parsed_options = command.default_params.merge(parsed_options)
        parse_required_params(command, arguments, names, parsed_options)
      rescue ::OptionParser::ParseError
        return Result.failure
      end

      def self.full_command_name(names)
        ProgramName.call(names)
      end

      def self.parse_required_params(command, arguments, names, parsed_options)
        parse_params = Hash[command.arguments.map(&:name).zip(arguments)]
        parse_required_params = Hash[command.required_arguments.map(&:name).zip(arguments)]
        all_required_params_satisfied = command.required_arguments.all? { |param| !parse_required_params[param.name].nil? }

        unless all_required_params_satisfied
          parse_required_params_values = parse_required_params.values.compact

          usage = "\nUsage: \"#{full_command_name(names)} #{command.required_arguments.map(&:description_name).join(' ')}\""

          if parse_required_params_values.empty?
            return Result.failure("ERROR: \"#{full_command_name(names)}\" was called with no arguments#{usage}")
          else
            return Result.failure("ERROR: \"#{full_command_name(names)}\" was called with arguments #{parse_required_params_values}#{usage}")
          end
        end

        Result.success(parse_params.merge(parsed_options))
      end

      class Result
        def self.help
          new(help: true)
        end

        def self.success(arguments = {})
          new(arguments: arguments)
        end

        def self.failure(error = "Error: Invalid param provided")
          new(error: error)
        end

        attr_reader :arguments, :error

        def initialize(arguments: {}, error: nil, help: false)
          @arguments = arguments
          @error     = error
          @help      = help
        end

        def error?
          !error.nil?
        end

        def help?
          @help
        end
      end
    end
  end
end
