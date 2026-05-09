# frozen_string_literal: true

require "dry/cli/program_name"

module Dry
  class CLI
    # Command banner
    #
    # @api private
    module Banner
      # A two-column row in the banner: a label and its description.
      #
      # @api private
      Row = Data.define(:label, :description) do
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
        argument_rows = command_argument_rows(command)
        example_rows = command_example_rows(command, name)
        option_rows = command_option_rows(command)
        indent = capture_indent(argument_rows + option_rows + example_rows)

        [
          command_name(name),
          command_name_and_arguments(command, name),
          command_description(command),
          command_subcommands(command),
          row_section("Arguments", argument_rows, indent),
          row_section("Options", option_rows, indent),
          row_section("Examples", example_rows, indent)
        ]
      end

      # @since 1.1.1
      # @api private
      def self.namespace_banner(namespace, name)
        option_rows = command_option_rows(namespace)
        indent = capture_indent(option_rows)

        [
          command_name(name, "Namespace"),
          command_name_and_arguments(namespace, name),
          command_description(namespace),
          command_subcommands(namespace),
          row_section("Options", option_rows, indent)
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
      def self.row_section(heading, rows, indent)
        return if rows.empty?

        "\n#{heading}:\n#{rows.map { |row| row.render(indent) }.join("\n")}"
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
      def self.command_argument_rows(command)
        command.arguments.map do |argument|
          Row.new(
            label: argument.name.to_s.upcase,
            description: "#{"REQUIRED " if argument.required?}#{argument.desc}"
          )
        end
      end

      # @api private
      def self.command_example_rows(command, name)
        command.examples.map do |example, description|
          Row.new(label: "#{name} #{example}", description: description)
        end
      end

      # @api private
      def self.command_option_rows(command)
        result = command.options.map { |option|
          Row.new(label: option_label(option), description: option_description(option))
        }
        result << Row.new(label: "--help, -h", description: "Print this help")
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
      def self.capture_indent(rows)
        rows.map { |row| row.label.length }.max + 1
      end
    end
  end
end
