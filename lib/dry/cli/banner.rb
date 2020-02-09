# frozen_string_literal: true

require 'dry/cli/program_name'

module Dry
  class CLI
    # Command banner
    #
    # @since 0.1.0
    # @api private
    module Banner
      # Prints command banner
      #
      # @param command [Dry::CLI::Command] the command
      # @param out [IO] standard output
      #
      # @since 0.1.0
      # @api private
      def self.call(command, names)
        full_command_name = full_command_name(names)
        [
          command_name(full_command_name),
          command_name_and_arguments(command, full_command_name),
          command_description(command),
          command_arguments(command),
          command_options(command),
          command_examples(command, full_command_name)
        ].compact.join("\n")
      end

      # @since 0.1.0
      # @api private
      def self.command_name(name)
        "Command:\n  #{name}"
      end

      # @since 0.1.0
      # @api private
      def self.command_name_and_arguments(command, name)
        "\nUsage:\n  #{name}#{arguments(command)}"
      end

      # @since 0.1.0
      # @api private
      def self.command_examples(command, name)
        return if command.examples.empty?

        "\nExamples:\n#{command.examples.map { |example| "  #{name} #{example}" }.join("\n")}" # rubocop:disable Metrics/LineLength
      end

      # @since 0.1.0
      # @api private
      def self.command_description(command)
        return if command.description.nil?

        "\nDescription:\n  #{command.description}"
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
      def self.full_command_name(names)
        ProgramName.call(names)
      end

      # @since 0.1.0
      # @api private
      def self.arguments(command)
        required_arguments = command.required_arguments
        optional_arguments = command.optional_arguments

        required = required_arguments.map { |arg| arg.name.upcase }.join(' ') if required_arguments.any? # rubocop:disable Metrics/LineLength
        optional = optional_arguments.map { |arg| "[#{arg.name.upcase}]" }.join(' ') if optional_arguments.any? # rubocop:disable Metrics/LineLength
        result = [required, optional].compact

        " #{result.join(' ')}" unless result.empty?
      end

      # @since 0.1.0
      # @api private
      def self.extended_command_arguments(command)
        command.arguments.map do |argument|
          "  #{argument.name.to_s.upcase.ljust(20)}\t# #{'REQUIRED ' if argument.required?}#{argument.desc}" # rubocop:disable Metrics/LineLength
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
                 elsif option.array?
                   "#{name}=VALUE1,VALUE2,.."
                 else
                   "#{name}=VALUE"
                 end
          name = "#{name}, #{option.alias_names.join(', ')}" if option.aliases.any?
          name = "  --#{name.ljust(30)}"
          name = "#{name}\t# #{option.desc}"
          name = "#{name}, default: #{option.default.inspect}" unless option.default.nil?
          name
        end

        result << "  --#{'help, -h'.ljust(30)}\t# Print this help"
        result.join("\n")
      end
    end
  end
end
