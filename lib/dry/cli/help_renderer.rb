# frozen_string_literal: true

require "dry/cli/banner"
require "dry/cli/usage"

module Dry
  class CLI
    # The help renderer used unless another is configured, rendering the help dry-cli has always
    # printed.
    #
    # @see Dry::CLI::Config::Help#renderer
    #
    # @api public
    # @since x.y.z
    module HelpRenderer
      # A registry level, in the shape {Usage} and {SpellChecker} read it.
      #
      # @api private
      Level = Data.define(:children, :names)

      # @param screen [Dry::CLI::Screen]
      #
      # @return [Dry::CLI::Screen] the screen, with its text
      #
      # @api public
      # @since x.y.z
      def self.call(screen)
        screen.with(text: screen.command? ? command(screen) : listing(screen))
      end

      # @api private
      def self.command(screen)
        Banner.call(screen.node.command, screen.prog_name, long: screen.long)
      end
      private_class_method :command

      # @api private
      def self.listing(screen)
        usage = Usage.call(level(screen))
        screen.suggestion ? "#{screen.suggestion}\n\n#{usage}" : usage
      end
      private_class_method :listing

      # The registry level a listing screen describes, as the names were given on the command
      # line, which may be aliases.
      #
      # @param screen [Dry::CLI::Screen]
      #
      # @return [Level]
      #
      # @api private
      def self.level(screen)
        Level.new(
          children: screen.node.source.children,
          names: screen.arguments.take(screen.node.path.length)
        )
      end
    end
  end
end
