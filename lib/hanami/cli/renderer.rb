module Hanami
  class Cli
    class Renderer
      attr_reader :commands

      def initialize(command_registry)
        @commands = command_registry
      end

      def render(current_command)
        puts "Commands:"
        longest_row = row_sizes(current_command).max

        commands.sort.each do |key, command|
          next if command_level(current_command) != command.level
          next unless command.command_of_subcommand?(current_command)
          row = build_row(key, command)
          print_row(row, longest_row, command)
        end
      end

      private

      def command_level(current_command)
        current_command.to_s.split(' ').size
      end

      def row_sizes(current_command)
        commands.map do |key, command|
          next 0 if command_level(current_command) != command.level
          next 0 unless command.command_of_subcommand?(current_command)
          build_row(key, command).size
        end
      end

      def build_row(command_name, command)
        "".tap do |row|
          row << "  #{program_name} #{command_name}"
          command.required_arguments.each do |param|
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
