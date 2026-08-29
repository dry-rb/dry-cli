# frozen_string_literal: true

require "dry/cli/style"

module Dry
  class CLI
    # Convenience access to {Dry::CLI::Style}
    #
    # Included in {Dry::CLI::Command} at both class and instance level. Extend it to build a
    # palette of your own.
    #
    # @example
    #   module MyCLI
    #     module Styles
    #       extend Dry::CLI::StyleMixin
    #
    #       ERROR = style.bold.red
    #       MUTED = style.dim
    #     end
    #   end
    #
    # @api public
    # @since x.x.x
    module StyleMixin
      # Returns a neutral style to chain from.
      #
      # @return [Dry::CLI::Style]
      #
      # @example
      #   style.bold.red["Boom"] # => "\e[1;31mBoom\e[0m"
      #
      # @api public
      # @since x.x.x
      def style
        Style.new
      end

      # Removes all style escape sequences from the given text.
      #
      # @param text [String] the text to strip
      #
      # @return [String] the text without styling
      #
      # @example
      #   unstyle(`git status --porcelain`)
      #
      # @api public
      # @since x.x.x
      def unstyle(text)
        Style.unstyle(text)
      end
    end
  end
end
