# frozen_string_literal: true

require "dry/cli/program_name"

module Dry
  class CLI
    # Command banner
    #
    # @since 0.1.0
    # @api private
    module Banner
      # Prints command/namespace banner
      #
      # @param command [Dry::CLI::Command, Dry::CLI::Namespace] the command/namespace
      # @param out [IO] standard output
      #
      # @since 0.1.0
      # @api private
      def self.call(command, name)
        b = if CLI.command?(command)
              command_banner(command, name)
            else
              namespace_banner(command, name)
            end

        b.compact.join("\n")
      end

      # @since 1.1.1
      # @api private
      def self.command_banner(command, name)
        [
          command_name(name),
          command_name_and_arguments(command, name),
          command_description(command),
          command_subcommands(command),
          command_arguments(command),
          command_options(command),
          command_examples(command, name)
        ]
      end

      # @since 1.1.1
      # @api private
      def self.namespace_banner(namespace, name)
        [
          command_name(name, "Namespace"),
          command_name_and_arguments(namespace, name),
          command_description(namespace),
          command_subcommands(namespace),
          command_options(namespace)
        ]
      end

      # @since 0.1.0
      # @api private
      def self.command_name(name, label = "Command")
        "#{label}:\n  #{name}"
      end

      # @since 0.1.0
      # @api private
      def self.command_name_and_arguments(command, name)
        usage = "\nUsage:\n"

        callable_root_command = false
        if command.new.respond_to?(:call)
          callable_root_command = true
          usage += "  #{name}#{arguments(command)}"
        end

        if command.subcommands.any?
          usage += " "
          usage += "|" if callable_root_command
          usage += " #{name} SUBCOMMAND"
        end

        usage
      end

      # @since 0.1.0
      # @api private
      def self.command_examples(command, name)
        return if command.examples.empty?

        "\nExamples:\n#{command.examples.map { |example| "  #{name} #{example}" }.join("\n")}"
      end

      # @since 0.1.0
      # @api private
      def self.command_description(command)
        return if command.description.nil?

        "\nDescription:\n  #{command.description}"
      end

      def self.command_subcommands(command)
        return if command.subcommands.empty?

        "\nSubcommands:\n#{build_subcommands_list(command.subcommands)}"
      end

      # @since 0.1.0
      # @api private
      def self.command_arguments(command)
        return if command.arguments.empty?

        "\nArguments:\n#{extended_command_arguments(command)}"
      end

      # @since 0.1.0
      # @api private
      def self.command_options(command)
        "\nOptions:\n#{extended_command_options(command)}"
      end

      # @since 0.1.0
      # @api private
      def self.arguments(command)
        args = command.arguments_sorted_by_usage_order
        args.map! do |a|
          # a.to_s raises deprecation warning that it will result in a frozen string in the future
          name = a.required? ? "#{a.name}" : "[#{a.name}]" # rubocop:disable Style/RedundantInterpolation
          name.upcase!
        end

        " #{args.join(" ")}" unless args.empty?
      end

      # @since 0.1.0
      # @api private
      def self.extended_command_arguments(command)
        command.arguments.map do |argument|
          "  #{argument.name.to_s.upcase.ljust(32)}  # #{"REQUIRED " if argument.required?}#{argument.desc}"
        end.join("\n")
      end

      # @since 0.1.0
      # @api private
      #
      def self.extended_command_options(command)
        result = command.options.map do |option|
          name = Inflector.dasherize(option.name)
          name = if option.boolean?
                   "[no-]#{name}"
                 elsif option.flag?
                   name
                 elsif option.array?
                   "#{name}=VALUE1,VALUE2,.."
                 else
                   "#{name}=VALUE"
                 end
          name = "#{name}, #{option.alias_names.join(", ")}" if option.aliases.any?
          name = "  --#{name.ljust(30)}"
          name = "#{name}  # #{option.desc}"
          name = "#{name}, default: #{option.default.inspect}" unless option.default.nil?
          name
        end

        result << "  --#{"help, -h".ljust(30)}  # Print this help"
        result.join("\n")
      end

      def self.build_subcommands_list(subcommands)
        subcommands.map do |subcommand_name, subcommand|
          "  #{subcommand_name.ljust(32)}  # #{subcommand.command.description}"
        end.join("\n")
      end
    end
  end
end
