require "hanami/cli/program_name"

module Hanami
  class Cli
    module Banner
      SUBCOMMAND_BANNER = " [SUBCOMMAND]".freeze

      def self.call(result, out)
        out.puts "Commands:"
        max_length, commands = commands_and_arguments(result)

        commands.each do |banner, node|
          usage = description(node.command) if node.leaf?
          out.puts "#{justify(banner, max_length, usage)}#{usage}"
        end
      end

      def self.commands_and_arguments(result)
        max_length = 0
        ret        = commands(result).each_with_object({}) do |(name, node), memo|
          args = if node.leaf?
                   arguments(node.command)
                 else
                   SUBCOMMAND_BANNER
                 end

          partial       = "  #{command_name(result, name)}#{args}"
          max_length    = partial.bytesize if max_length < partial.bytesize
          memo[partial] = node
        end

        [max_length, ret]
      end

      def self.arguments(command)
        return unless Cli.command?(command)

        " #{command.class.required_arguments.map { |arg| arg.name.upcase }.join(' ')}"
      end

      def self.description(command)
        return unless Cli.command?(command)

        " # #{command.class.description}" unless command.class.description.nil?
      end

      def self.justify(string, padding, usage)
        return string.chomp(" ") if usage.nil?
        string.ljust(padding + padding / 2)
      end

      def self.commands(result)
        result.children.sort_by { |name, _| name }
      end

      def self.command_name(result, name)
        ProgramName.call([result.names, name])
      end
    end
  end
end
