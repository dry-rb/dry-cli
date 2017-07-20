module Hanami
  class Cli
    require "hanami/cli/version"
    require "hanami/cli/command"
    require "hanami/cli/registry"
    require "hanami/cli/parser"
    require "hanami/cli/banner"

    def self.command?(command)
      case command
      when Class
        command.ancestors.include?(Command)
      else
        command.is_a?(Command)
      end
    end

    def initialize(registry)
      @commands = registry
    end

    def call(arguments: ARGV, out: $stdout)
      result = commands.get(arguments)

      if result.found?
        command, args = parse(result, out)
        command.call(args)
      else
        banner(result, out)
      end
    end

    private

    attr_reader :commands

    def parse(result, out)
      command = result.command
      return [command, result.arguments] unless command?(command)

      result = Parser.call(command.class, result.arguments, result.names, out)
      exit(0) if result.help?

      if result.error?
        out.puts(result.error)
        exit(1)
      end

      [command, result.arguments]
    end

    def banner(result, out)
      Banner.call(result, out)
      exit(1)
    end

    def command?(command)
      Cli.command?(command)
    end
  end
end
