module Hanami
  module Cli
    class Renderer
      attr_reader :command_name

      def initialize(command_name)
        @command_name = command_name
      end

      def render
        puts "Commands:"
        longest_row = row_sizes.max

        Hanami::Cli.commands.sort.each do |key, command|
          next if command_level != command.level
          next unless command.command_of_subcommand?(command_name)
          row = build_row(key, command)
          print_row(row, longest_row, command)
        end
      end

      private

      def command_level
        @command_level ||= command_name.to_s.split(' ').size
      end

      def row_sizes
        Hanami::Cli.commands.map do |key, command|
          next 0 if command_level != command.level
          next 0 unless command.command_of_subcommand?(command_name)
          build_row(key, command).size
        end
      end

      def build_row(command_name, command)
        "".tap do |row|
          row << "  #{program_name} #{command_name}"
          command.required_params.each do |param|
            row << " #{param.description_name}"
          end
          row << " [SUBCOMMAND]" if command.subcommand?
        end
      end

      def print_row(row, longest_row, command)
        if command.description
          printf "%-#{longest_row}s", row
          printf "  # %s", command.description
        else
          printf "%s", row
        end
        puts
      end

      def program_name
        Pathname.new($PROGRAM_NAME).basename
      end
    end
  end
end
