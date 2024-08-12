# frozen_string_literal: true

require "dry/cli/program_name"
require "did_you_mean"

module Dry
  class CLI
    # Command(s) usage
    #
    # @since 1.1.1
    # @api private
    module SpellChecker
      # @since 1.1.1
      # @api private
      def self.call(result, arguments)
        commands = result.children.keys
        cmd = cmd_to_spell(arguments, result.names)
        output = []

        suggestions = DidYouMean::SpellChecker.new(dictionary: commands).correct(cmd.first)
        output << "I don't know how to '#{cmd.join(' ')}'."
        output << " Did you mean: '#{suggestions.first}' ?" if suggestions.any?

        output.join("")
      end

      # @since 1.1.1
      # @api private
      def self.cmd_to_spell(arguments, result_names)
        arguments - result_names
      end
    end
  end
end
