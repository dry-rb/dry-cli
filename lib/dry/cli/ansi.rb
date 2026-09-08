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

      # Erase the entire line
      # @api public
      # @since x.y.z
      EL2 = "\e[2K"
      def self.erase_line = EL2

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
      def self.clear_line = CR + EL2

      # Switch to the alternate screen buffer
      # @api public
      # @since x.y.z
      SMCUP = "\e[?1049h"
      def self.enter_alt_screen = SMCUP

      # Switch back to the main screen buffer
      # @api public
      # @since x.y.z
      RMCUP = "\e[?1049l"
      def self.exit_alt_screen = RMCUP

      # Erase the entire screen
      # @api public
      # @since x.y.z
      ERASE_SCREEN = "\e[2J"
      def self.erase_screen = ERASE_SCREEN

      # Move the cursor to its home position (top-left corner)
      # @api public
      # @since x.y.z
      HOME = "\e[H"
      def self.cursor_home = HOME

      # Erase the entire screen and move the cursor to its home position
      # @api public
      # @since x.y.z
      def self.clear_screen = ERASE_SCREEN + HOME

      # Move the cursor to the given row and column (both one-based)
      #
      # @example
      #   ANSI.move_to(3, 10) # => "\e[3;10H"
      #
      # @param row [Integer] The one-based row to move to
      # @param col [Integer] The one-based column to move to
      #
      # @api public
      # @since x.y.z
      CUP = "\e[%d;%dH"
      def self.move_to(row, col) = format(CUP, row, col)

      # Move the cursor up by the given number of lines
      #
      # @param count [Integer] The number of lines to move up
      #
      # @api public
      # @since x.y.z
      CUU = "\e[%dA"
      def self.cursor_up(count = 1) = format(CUU, count)

      # Move the cursor down by the given number of lines
      #
      # @param count [Integer] The number of lines to move down
      #
      # @api public
      # @since x.y.z
      CUD = "\e[%dB"
      def self.cursor_down(count = 1) = format(CUD, count)

      # Move the cursor forward by the given number of columns
      #
      # @param count [Integer] The number of columns to move forward
      #
      # @api public
      # @since x.y.z
      CUF = "\e[%dC"
      def self.cursor_forward(count = 1) = format(CUF, count)

      # Move the cursor back by the given number of columns
      #
      # @param count [Integer] The number of columns to move back
      #
      # @api public
      # @since x.y.z
      CUB = "\e[%dD"
      def self.cursor_back(count = 1) = format(CUB, count)

      # Move the cursor to the given column, keeping its row (one-based)
      #
      # @example
      #   ANSI.cursor_to_col(10) # => "\e[10G"
      #
      # @param col [Integer] The one-based column to move to
      #
      # @api public
      # @since x.y.z
      CHA = "\e[%dG"
      def self.cursor_to_col(col) = format(CHA, col)

      # Save the current cursor position
      # @api public
      # @since x.y.z
      SC = "\e7"
      def self.save_cursor = SC

      # Restore the cursor position saved by {save_cursor}
      # @api public
      # @since x.y.z
      RC = "\e8"
      def self.restore_cursor = RC

      # Set the scrolling region to the given top and bottom rows (both one-based)
      #
      # @example
      #   ANSI.scroll_region(2, 24) # => "\e[2;24r"
      #
      # @param top [Integer] The one-based top row of the scrolling region
      # @param bottom [Integer] The one-based bottom row of the scrolling region
      #
      # @api public
      # @since x.y.z
      CSR = "\e[%d;%dr"
      def self.scroll_region(top, bottom) = format(CSR, top, bottom)

      # Reset the scrolling region to the entire screen
      # @api public
      # @since x.y.z
      RESET_SCROLL_REGION = "\e[r"
      def self.reset_scroll_region = RESET_SCROLL_REGION
    end
  end
end
