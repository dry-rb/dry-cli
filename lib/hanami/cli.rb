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

        command.parse_arguments(arguments)
        command.call
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

    def self.register(command)
      @__commands[command.name] ||= {}
      @__commands[command.name] = command
    end

    def self.command(arguments)
      command_name = arguments.take_while { |argument| !argument.start_with?('-') }.join(' ')
      command = @__commands[command_name]
      command
      return command if command

      command_by_alias(arguments.join(' '))
    end

    def self.commands
      @__commands
    end

    private

    def self.command_by_class(command_class)
      @__commands.values.detect {|command_instance| command_instance.class == command_class}
    end

    def self.command_by_alias(command)
      @__commands.values.detect {|command_instance| command_instance.aliases.to_a.include?(command)}
    end
  end
end
