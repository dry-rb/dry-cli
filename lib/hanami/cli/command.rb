require "hanami/cli/param"
require "optparse"

module Hanami
  module Cli
    module Command
      def self.included(base)
        base.include InstanceMethods
        base.extend ClassMethods
      end

      module InstanceMethods
        attr_reader :options, :name, :parsed_options, :aliases

        def initialize(name, options = {})
          @name = name
          @aliases = options[:aliases]
          @options = options
        end

        def subcommand?
          options[:subcommand]
        end

        def level
          name.split(' ').size - 1
        end

        def description
          options[:desc]
        end

        def parse_arguments(arguments)
          return unless options[:params]

          parsed_options = {}
          OptionParser.new do |opts|
            opts.banner = "Usage:"
            opts.separator("  #{full_command_name}")
            opts.separator("")

            if options[:desc]
              opts.separator("Description:")
              opts.separator("  #{description}")
              opts.separator("")
            end

            opts.separator("Options:")

            options[:params].each do |param|
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

          parsed_options = default_params.merge(parsed_options)
          parse_required_params(arguments, parsed_options)
        rescue OptionParser::InvalidOption
          puts "Error: Invalid param provided"
          exit(1)
        end

        def parse_required_params(arguments, parsed_options)
          parse_required_params = Hash[required_params.map(&:name).zip(arguments)]
          all_required_params_satisfied = required_params.all?{|param| !parse_required_params[param.name].nil?}

          unless all_required_params_satisfied
            parse_required_params_values = parse_required_params.values.compact
            if parse_required_params_values.empty?
              puts "ERROR: \"#{full_command_name}\" was called with no arguments"
            else
              puts "ERROR: \"#{full_command_name}\" was called with arguments #{parse_required_params_values}"
            end
            puts "Usage: \"#{full_command_name} #{required_params.map(&:description_name).join(' ')}\""
            exit(1)
          end

          parse_required_params.merge(parsed_options)
        end

        def required_params
          @required_params ||= options[:params].to_a.select(&:required?)
        end

        def default_params
          options[:params].to_a.inject({}) do |list, param|
            list[param.name] = param.default unless param.default.nil?
            list
          end
        end

        def command_of_subcommand?(key)
          name.start_with?(key.to_s)
        end

        def full_command_name
          "#{Pathname.new($PROGRAM_NAME).basename} #{name}"
        end
      end

      module ClassMethods
        def desc(description)
          generate_new_command(desc: description)
        end

        def aliases(*names)
          generate_new_command(aliases: names)
        end

        def argument(name, options = {})
          option(name, options.merge(required: true))
        end

        def option(name, options = {})
          param = Param.new(name, options)
          command = current_command
          command.options[:params] ||= []
          command.options[:params] << param
          generate_new_command(command: command, params: command.options[:params])
        end

        def register(name, options = {})
          Hanami::Cli.register(new(name, options))
        end

        private

        def generate_new_command(command: current_command, **options)
          new_command = new(command.name, command.options.merge(options))
          Hanami::Cli.commands[new_command.name] = new_command
        end

        def current_command
          Hanami::Cli.command_by_class(self)
        end
      end
    end
  end
end
