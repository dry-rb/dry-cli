require "hanami/cli/version"
require "hanami/cli/renderer"
require "hanami/cli/command/params_parser"

module Hanami
  class Cli
    attr_reader :commands
    attr_reader :renderer

    def initialize(command_registry)
      @commands = command_registry
      @renderer = Hanami::Cli::Renderer.new(command_registry)
    end

    # FIXME ignore_unknown_commands is a hack to help us to migrate Hanami commands.
    # It MUST be removed once done
    def call(arguments: ARGV, ignore_unknown_commands: false)
      command, arguments = commands.resolve_from_arguments(arguments)

      if command.nil? || command.subcommand?
        command_name = command.name if command
        return nil if ignore_unknown_commands

        renderer.render(command_name)
        exit(1)
      end

      parser = Command::ParamsParser.new(command)
      params = parser.parse(arguments)
      if params.any?
        command.call(params)
      else
        command.call
      end
    end
  end
end
