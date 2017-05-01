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
      @__commands[name] ||= {}
      @__commands[name][:command_class] = command
    end

    def self.command(arguments)
      command = arguments.join(" ")
      (@__commands[command] && @__commands[command][:command_class]) || command_by_alias(command)
    end

    def self.add_option(command_class, option)
      @__commands.each do |command, values|
        if values[:command_class] == command_class
          @__commands[command].merge!(option)
          break
        end
      end
    end

    private

    def self.command_by_alias(command)
      found_command = @__commands.detect{|_, values| values[:aliases].to_a.include?(command)}.to_a.last
      found_command && found_command[:command_class]
    end
  end
end
