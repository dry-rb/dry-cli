require "hanami/cli/command/class_interface"

module Hanami
  class Cli
    class Command
      extend ClassInterface

      attr_reader :name, :description, :params, :options

      def initialize(name:, description:, params: [], **options)
        @name = name
        @description = description
        @params = params
        @options = options
      end

      def subcommand?
        options[:subcommand]
      end

      def level
        name.split(' ').size - 1
      end

      def arguments
        params.select(&:argument?)
      end

      def required_arguments
        arguments.select(&:required?)
      end

      def default_params
        params.inject({}) do |list, param|
          list[param.name] = param.default unless param.default.nil?
          list
        end
      end

      def command_of_subcommand?(key)
        name.start_with?(key.to_s)
      end
    end
  end
end
