# frozen_string_literal: true

module Dry
  class CLI
    # ANSI escape sequences for controlling the terminal
    #
    # @api public
    # @since x.y.z
    module ANSI
      # Hide the cursor
      # @api public
      # @since x.y.z
      CIVIS = "\e[?25l"
      def self.hide_cursor = CIVIS

      # Show the cursor
      # @api public
      # @since x.y.z
      CNORM = "\e[?25h"
      def self.show_cursor = CNORM

      # Move the cursor to the beginning of the line
      # @api public
      # @since x.y.z
      CR = "\r"
      def self.carriage_return = CR

      # Clear the entire line
      # @api public
      # @since x.y.z
      EL2 = "\e[2K"
      def self.clear_line = EL2

      # Reset all styles
      # @api public
      # @since x.y.z
      SGR0 = "\e[0m"
      def self.reset_style = SGR0

      # Erase line contents and move the cursor back to the beginning.
      # Suitable for making live updates to a line.
      #
      # @api public
      # @since x.y.z
      def self.erase_line = CR + EL2
    end
  end
end
