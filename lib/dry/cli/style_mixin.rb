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
      # Returns a neutral style to chain from, or the given text unchanged.
      #
      # @param text [String,nil] the text to return
      #
      # @return [Dry::CLI::Style,String]
      #
      # @example
      #   style.bold.red("Boom") # => "\e[1;31mBoom\e[0m"
      #
      # @api public
      # @since x.x.x
      def style(text = nil)
        neutral = Style.new
        text.nil? ? neutral : neutral.call(text)
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
