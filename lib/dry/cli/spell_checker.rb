# frozen_string_literal: true

require "dry/cli/program_name"
require "did_you_mean"

module Dry
  class CLI
    # Command(s) usage
    #
    # @api private
    module SpellChecker
      # Returns a message for the first argument after the names of the commands that were found.
      #
      # For a command name, the message has a suggestion if there's a similar command, such as:
      #
      #   unknown command "serve". Did you mean "foo server"?
      #
      # For an option, the message names it as the user typed it, without any value:
      #
      #   unknown option --nope
      def self.call(result, arguments)
        name = arguments[result.names.length]
        return "unknown option #{name.split("=", 2).first}" if name.start_with?("-")

        message = %(unknown command "#{name}")

        suggestion = DidYouMean::SpellChecker.new(dictionary: result.children.keys).correct(name).first
        message += %(. Did you mean "#{ProgramName.call([result.names, suggestion])}"?) if suggestion

        message
      end
    end
  end
end
