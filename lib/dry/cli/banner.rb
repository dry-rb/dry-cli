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
        extended_arguments = extended_command_arguments(command)
        extended_examples  = extended_command_examples(command, name)
        extended_options   = extended_command_options(command)
        indent = capture_indent(extended_arguments, extended_options, extended_examples)

        [
          command_name(name),
          command_name_and_arguments(command, name),
          command_description(command),
          command_subcommands(command),
          command_arguments(extended_arguments, indent),
          command_options(extended_options, indent),
          command_examples(extended_examples, indent)
        ]
      end

      # @since 1.1.1
      # @api private
      def self.namespace_banner(namespace, name)
        extended_options = extended_command_options(namespace)
        indent = capture_indent([], extended_options, [])

        [
          command_name(name, "Namespace"),
          command_name_and_arguments(namespace, name),
          command_description(namespace),
          command_subcommands(namespace),
          command_options(extended_options, indent)
        ]
      end

      # @since unreleased
      # @api private
      def self.capture_indent(extended_arguments, extended_options, extended_examples)
        strings = extended_arguments + extended_options + extended_examples
        strings.map { |string, _| string.length }.max + 1
      end

      # @since unreleased
      # @api private
      def self.build_option_right(option)
        description = option.desc
        unless option.default.nil?
          description = "#{description}, default: #{option.default.inspect}"
        end
        description
      end

      # @since unreleased
      # @api private
      def self.build_option_left(option)
        name = Inflector.dasherize(option.name)
        name = if option.boolean?
                 "--[no-]#{name}"
               elsif option.flag?
                 "--#{name}"
               elsif option.array?
                 "--#{name}=VALUE1,VALUE2,.."
               else
                 "--#{name}=VALUE"
               end
        name = "#{name}, #{option.alias_names.join(", ")}" if option.aliases.any?
        name
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
      def self.command_examples(extended_examples, indent)
        return if extended_examples.empty?

        examples = extended_examples.map { |example, description|
          "  #{example.ljust(indent)} # #{description}"
        }
        "\nExamples:\n#{examples.join("\n")}"
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
      def self.command_arguments(extended_arguments, indent)
        return if extended_arguments.empty?

        arguments = extended_arguments.map { |argument, description|
          "  #{argument.ljust(indent)} # #{description}"
        }
        "\nArguments:\n#{arguments.join("\n")}"
      end

      # @since 0.1.0
      # @api private
      def self.command_options(extended_options, indent)
        options = extended_options.map { |option, description|
          "  #{option.ljust(indent)} # #{description}"
        }
        "\nOptions:\n#{options.join("\n")}"
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
          [argument.name.to_s.upcase, "#{"REQUIRED " if argument.required?}#{argument.desc}"]
        end
      end

      # @since 0.1.0
      # @api private
      def self.extended_command_examples(command, name)
        command.examples.map do |example, description|
          ["#{name} #{example}", description]
        end
      end

      # @since 0.1.0
      # @api private
      #
      def self.extended_command_options(command)
        result = command.options.map { |option|
          [build_option_left(option), build_option_right(option)]
        }
        result << ["--help, -h", "Print this help"]
      end

      def self.build_subcommands_list(subcommands)
        subcommands.map do |subcommand_name, subcommand|
          "  #{subcommand_name.ljust(32)}  # #{subcommand.command.description}"
        end.join("\n")
      end
    end
  end
end
