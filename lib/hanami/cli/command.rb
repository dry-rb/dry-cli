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

          @parsed_options = {}
          OptionParser.new do |opts|
            opts.banner = "Usage:"
            opts.separator("  #{Pathname.new($PROGRAM_NAME).basename} #{name}")
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
                @parsed_options[param.name.to_sym] = value
              end
            end

            opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit
            end
          end.parse!(arguments)

          options[:params].each do |param|
            next unless param.required?
            define_singleton_method param.name do
              arguments.shift
            end
          end
        rescue OptionParser::InvalidOption
        end

        def required_params
          @required_params ||= options[:params].to_a.select(&:required?)
        end
      end

      module ClassMethods
        def desc(description)
          old_command = Hanami::Cli.command_by_class(self)
          new_command = new(old_command.name, old_command.options.merge(desc: description))
          Hanami::Cli.commands[new_command.name] = new_command
        end

        def aliases(*names)
          old_command = Hanami::Cli.command_by_class(self)
          new_command = new(old_command.name, old_command.options.merge(aliases: names))
          Hanami::Cli.commands[new_command.name] = new_command
        end

        def required_param(param_name)
          old_command = Hanami::Cli.command_by_class(self)
          new_command = new(old_command.name, old_command.options.merge(required_param: param_name))
          Hanami::Cli.commands[new_command.name] = new_command
        end

        def param(name, options = {})
          param = Param.new(name, options)
          old_command = Hanami::Cli.command_by_class(self)
          old_command.options[:params] ||= []
          old_command.options[:params] << param
          new_command = new(old_command.name, old_command.options)
        end

        def register(name, options = {})
          Hanami::Cli.register(new(name, options))
        end
      end
    end
  end
end
