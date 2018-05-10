require "hanami/cli/program_name"

module Hanami
  class CLI
    # Command(s) usage
    #
    # @since 0.1.0
    # @api private
    module Usage
      # @since 0.1.0
      # @api private
      SUBCOMMAND_BANNER = " [SUBCOMMAND]".freeze

      # @since 0.1.0
      # @api private
      def self.call(result, out, descriptions)
        out.puts descriptions[:before] + "\n\n" if show_description?(:before, result, descriptions)

        out.puts "Commands:"
        max_length, commands = commands_and_arguments(result)

        commands.each do |banner, node|
          usage = description(node.command) if node.leaf?
          out.puts "#{justify(banner, max_length, usage)}#{usage}"
        end

        out.puts "\n" + descriptions[:after] if show_description?(:after, result, descriptions)
      end

      # @since 0.1.0
      # @api private
      def self.commands_and_arguments(result) # rubocop:disable Metrics/MethodLength
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

      # @since 0.1.0
      # @api private
      def self.arguments(command) # rubocop:disable Metrics/AbcSize
        return unless CLI.command?(command)

        required_arguments = command.required_arguments
        optional_arguments = command.optional_arguments

        required = required_arguments.map { |arg| arg.name.upcase }.join(' ') if required_arguments.any?
        optional = optional_arguments.map { |arg| "[#{arg.name.upcase}]" }.join(' ') if optional_arguments.any?
        result = [required, optional].compact

        " #{result.join(' ')}" unless result.empty?
      end

      # @since 0.1.0
      # @api private
      def self.description(command)
        return unless CLI.command?(command)

        " # #{command.description}" unless command.description.nil?
      end

      # @since 0.1.0
      # @api private
      def self.justify(string, padding, usage)
        return string.chomp(" ") if usage.nil?
        string.ljust(padding + padding / 2)
      end

      # @since 0.1.0
      # @api private
      def self.commands(result)
        result.children.sort_by { |name, _| name }
      end

      # @since 0.1.0
      # @api private
      def self.command_name(result, name)
        ProgramName.call([result.names, name])
      end

      # @since 0.2.1
      # @api private
      def self.show_description?(name, result, descriptions)
        descriptions.key?(name) && result.names.none?
      end 
    end
  end
end
