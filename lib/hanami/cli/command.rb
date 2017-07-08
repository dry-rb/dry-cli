require "hanami/cli/param"
require "hanami/cli/command/params_parser"

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
          @params_parser = ParamsParser.new(self)
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

        def params
          options[:params]
        end

        def parse_arguments(arguments)
          return unless options[:params]

          @params_parser.parse(arguments)
        end

        def required_params
          @required_params ||= options[:params].to_a.select(&:required?)
        end

        def default_params
          params.to_a.inject({}) do |list, param|
            list[param.name] = param.default unless param.default.nil?
            list
          end
        end

        def command_of_subcommand?(key)
          name.start_with?(key.to_s)
        end
      end

      module ClassMethods
        def desc(description)
          generate_new_command(desc: description)
        end

        def aliases(*names)
          generate_new_command(aliases: names)
        end

        #
        # FIXME: Use custom argument class instead Param class
        #
        def argument(name, options = {})
          option(name, options.merge(required: true))
        end

        #
        # FIXME: Use custom option class instead Param class
        #
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
