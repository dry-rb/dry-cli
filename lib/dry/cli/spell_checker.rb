# frozen_string_literal: true

require "dry/cli/program_name"
require "did_you_mean"

module Dry
  class CLI
    # Command(s) usage
    #
    # @api private
    module SpellChecker
      # Returns a message for an unknown command, with a suggestion if there's a similar command,
      # such as:
      #
      #   unknown command "serve". Did you mean "foo server"?
      #
      # Returns nil when the first unknown argument is an option, not a command name.
      def self.call(result, arguments)
        cmd = cmd_to_spell(arguments, result.names)
        return if ignore?(cmd)

        message = %(unknown command "#{cmd.first}")

        suggestion = DidYouMean::SpellChecker.new(dictionary: result.children.keys).correct(cmd.first).first
        message += %(. Did you mean "#{ProgramName.call([result.names, suggestion])}"?) if suggestion

        message
      end

      # Returns the arguments after the names of the commands that were found.
      def self.cmd_to_spell(arguments, result_names)
        arguments.drop(result_names.length)
      end

      def self.ignore?(cmd)
        cmd.empty? || cmd.first.start_with?("-")
      end
    end
  end
end
