# frozen_string_literal: true

require "dry/cli/program_name"

module Dry
  class CLI
    # Command banner
    #
    # @since 0.1.0
    # @api private
    module Banner # rubocop:disable Metrics/ModuleLength
      # Prints command banner
      #
      # @param command [Dry::CLI::Command] the command
      # @param out [IO] standard output
      #
      # @since 0.1.0
      # @api private
      def self.call(command, name)
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
        ].compact.join("\n")
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
      def self.command_name(name)
        "Command:\n  #{name}"
      end

      # @since 0.1.0
      # @api private
      def self.command_name_and_arguments(command, name)
        usage = "\nUsage:\n  #{name}#{arguments(command)}"

        return usage + " | #{name} SUBCOMMAND" if command.subcommands.any?

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
        required_arguments = command.required_arguments
        optional_arguments = command.optional_arguments

        required = required_arguments.map { |arg| arg.name.upcase }.join(" ") if required_arguments.any? # rubocop:disable Layout/LineLength
        optional = optional_arguments.map { |arg| "[#{arg.name.upcase}]" }.join(" ") if optional_arguments.any? # rubocop:disable Layout/LineLength
        result = [required, optional].compact

        " #{result.join(" ")}" unless result.empty?
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
