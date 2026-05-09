# frozen_string_literal: true

require "dry/cli/program_name"

module Dry
  class CLI
    # Command banner
    #
    # @api private
    module Banner
      # An entry in a banner section: a label and its description.
      #
      # @api private
      Entry = Data.define(:label, :description) do
        def render(indent) = "  #{label.ljust(indent)} # #{description}"
      end

      # Prints command/namespace banner
      #
      # @param command [Dry::CLI::Command, Dry::CLI::Namespace] the command/namespace
      # @param out [IO] standard output
      #
      # @api private
      def self.call(command, name)
        banner_lines =
          if CLI.command?(command)
            command_banner(command, name)
          else
            namespace_banner(command, name)
          end

        banner_lines.compact.join("\n")
      end

      # @api private
      def self.command_banner(command, name)
        argument_entries = command_argument_entries(command)
        example_entries = command_example_entries(command, name)
        option_entries = command_option_entries(command)
        indent = capture_indent(argument_entries + option_entries + example_entries)

        [
          command_name(name),
          command_name_and_arguments(command, name),
          command_description(command),
          command_subcommands(command),
          section("Arguments", argument_entries, indent),
          section("Options", option_entries, indent),
          section("Examples", example_entries, indent)
        ]
      end

      # @since 1.1.1
      # @api private
      def self.namespace_banner(namespace, name)
        option_entries = command_option_entries(namespace)
        indent = capture_indent(option_entries)

        [
          command_name(name, "Namespace"),
          command_name_and_arguments(namespace, name),
          command_description(namespace),
          command_subcommands(namespace),
          section("Options", option_entries, indent)
        ]
      end

      # @api private
      def self.command_name(name, label = "Command")
        "#{label}:\n  #{name}"
      end

      # @api private
      def self.command_name_and_arguments(command, name)
        parts = []
        parts << "#{name}#{arguments(command)}" if command.new.respond_to?(:call)
        parts << "#{name} SUBCOMMAND" if command.subcommands.any?

        "\nUsage:\n  #{parts.join(" | ")}" unless parts.empty?
      end

      # @api private
      def self.section(heading, entries, indent)
        return if entries.empty?

        "\n#{heading}:\n#{entries.map { |entry| entry.render(indent) }.join("\n")}"
      end

      # @api private
      def self.command_description(command)
        return if command.description.nil?

        "\nDescription:\n  #{command.description}"
      end

      def self.command_subcommands(command)
        return if command.subcommands.empty?

        "\nSubcommands:\n#{subcommands_list(command.subcommands)}"
      end

      # @api private
      def self.arguments(command)
        args = command.arguments_sorted_by_usage_order.map { |a|
          a.required? ? a.name.to_s.upcase : "[#{a.name.to_s.upcase}]"
        }

        " #{args.join(" ")}" unless args.empty?
      end

      # @api private
      def self.command_argument_entries(command)
        command.arguments.map do |argument|
          Entry.new(
            label: argument.name.to_s.upcase,
            description: "#{"REQUIRED " if argument.required?}#{argument.desc}"
          )
        end
      end

      # @api private
      def self.command_example_entries(command, name)
        command.examples.map do |example, description|
          Entry.new(label: "#{name} #{example}", description: description)
        end
      end

      # @api private
      def self.command_option_entries(command)
        result = command.options.map { |option|
          Entry.new(label: option_label(option), description: option_description(option))
        }
        result << Entry.new(label: "--help, -h", description: "Print this help")
      end

      # @api private
      def self.option_description(option)
        description = option.desc
        unless option.default.nil?
          description = "#{description}, default: #{option.default.inspect}"
        end
        description
      end

      # @api private
      def self.option_label(option)
        base = Inflector.dasherize(option.name)
        label =
          if option.boolean?
            "--[no-]#{base}"
          elsif option.flag?
            "--#{base}"
          elsif option.array?
            "--#{base}=VALUE1,VALUE2,.."
          else
            "--#{base}=VALUE"
          end
        label = "#{label}, #{option.alias_names.join(", ")}" if option.aliases.any?
        label
      end

      def self.subcommands_list(subcommands)
        subcommands.map do |subcommand_name, subcommand|
          "  #{subcommand_name.ljust(32)}  # #{subcommand.command.description}"
        end.join("\n")
      end

      # @api private
      def self.capture_indent(entries)
        entries.map { |entry| entry.label.length }.max + 1
      end
    end
  end
end
