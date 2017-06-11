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
        command, arguments = Hanami::Cli.command(arguments)
        if command.nil? || command.subcommand?
          command_name = command.name if command
          Hanami::Cli.render_commands(command_name)
          exit(1)
        end

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
      command_names = arguments.take_while { |argument| !argument.start_with?('-') }
      command = nil
      command_names.size.times do |i|
        splitted_names = command_names[0, command_names.size - i]
        command = @__commands[splitted_names.join(' ')]
        if command
          arguments = arguments - splitted_names
          break
        end
      end
      [command, arguments]

      # command_by_alias(arguments.join(' '))
    end

    def self.commands
      @__commands
    end

    def self.render_commands(command_name)
      command_level = command_name.to_s.split(' ').size
      puts "Commands:"
      row_sizes = @__commands.map do |command_name, command|
        next 0 if command_level != command.level
        row = "  #{Pathname.new($PROGRAM_NAME).basename} #{command_name}"
        row << " [SUBCOMMAND]" if command.subcommand?
        row.size
      end

      longest_row = row_sizes.max

      @__commands.sort.each do |command_name, command|
        next 0 if command_level != command.level
        row = "  #{Pathname.new($PROGRAM_NAME).basename} #{command_name}"
        row << " [SUBCOMMAND]" if command.subcommand?
        if command.description
          printf "%-#{longest_row}s", row
          printf "  # %s", command.description
        else
          printf "%s", row
        end
        puts
      end
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
