require "concurrent"

module Hanami
  module Cli
    require "hanami/cli/version"
    require "hanami/cli/command"

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def call(arguments: ARGV)
        command = Hanami::Cli.command(arguments)
        exit(1) if command.nil?

        command.new.call
      end

      # This is only for temporary integration with
      # hanami gem
      def run(arguments: ARGV)
        command = Hanami::Cli.command(arguments)
        return false if command.nil?

        command.new.call
        true
      end
    end

    @__commands = Concurrent::Hash.new

    def self.register(name, command)
      @__commands[name] = command
    end

    def self.command(arguments)
      command = arguments.join(" ")
      @__commands.fetch(command, nil)
    end
  end
end
