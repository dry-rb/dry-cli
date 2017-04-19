require "concurrent"

module Hanami
  module Cli
    require "hanami/cli/version"

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def call(arguments: ARGV)
        cmd     = arguments.first
        command = Hanami::Cli.command(cmd)
        exit(1) if command.nil?

        command.new.call
      end

      # This is only for temporary integration with
      # hanami gem
      def run(arguments: ARGV)
        cmd     = arguments.first
        command = Hanami::Cli.command(cmd)
        return false if command.nil?

        command.new.call
        true
      end

      def register(name, command)
        Hanami::Cli.register(name, command)
      end
    end

    @__commands = Concurrent::Hash.new

    def self.register(name, command)
      @__commands[name] = command
    end

    def self.command(name)
      @__commands.fetch(name, nil)
    end
  end
end
