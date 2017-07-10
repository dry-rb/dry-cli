require "optparse"

module Hanami
  class Cli
    class Command
      class ParamsParser
        attr_reader :command

        def initialize(command)
          @command = command
        end

        def parse(arguments)
          return unless command.params

          parsed_options = {}
          OptionParser.new do |opts|
            opts.banner = "Usage:"
            opts.separator("  #{full_command_name}")
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
              puts opts
              exit
            end
          end.parse!(arguments)

          parsed_options = command.default_params.merge(parsed_options)
          parse_required_params(arguments, parsed_options)
        rescue ::OptionParser::InvalidOption
          puts "Error: Invalid param provided"
          exit(1)
        end

        private

        def parse_required_params(arguments, parsed_options)
          parse_params = Hash[command.arguments.map(&:name).zip(arguments)]
          parse_required_params = Hash[command.required_arguments.map(&:name).zip(arguments)]
          all_required_params_satisfied = command.required_arguments.all?{|param| !parse_required_params[param.name].nil?}

          unless all_required_params_satisfied
            parse_required_params_values = parse_required_params.values.compact
            if parse_required_params_values.empty?
              puts "ERROR: \"#{full_command_name}\" was called with no arguments"
            else
              puts "ERROR: \"#{full_command_name}\" was called with arguments #{parse_required_params_values}"
            end
            puts "Usage: \"#{full_command_name} #{command.required_arguments.map(&:description_name).join(' ')}\""
            exit(1)
          end

          parse_params.merge(parsed_options)
        end

        def full_command_name
          "#{Pathname.new($PROGRAM_NAME).basename} #{command.name}"
        end
      end
    end
  end
end
