# frozen_string_literal: true

module Dry
  class CLI
    # Collection of functions to style text
    #
    # @since 1.3.0
    module Styles
      RESET = 0
      BOLD = 1
      DIM = 2
      ITALIC = 3
      UNDERLINE = 4
      BLINK = 5
      REVERSE = 7
      INVISIBLE = 8
      BLACK = 30
      RED = 31
      GREEN = 32
      YELLOW = 33
      BLUE = 34
      MAGENTA = 35
      CYAN = 36
      WHITE = 37
      ON_BLACK = 40
      ON_RED = 41
      ON_GREEN = 42
      ON_YELLOW = 43
      ON_BLUE = 44
      ON_MAGENTA = 45
      ON_CYAN = 46
      ON_WHITE = 47

      # Returns a text that can be styled
      #
      # @param text [String] text to be styled
      #
      # @since 1.3.0
      def stylize(text)
        StyledText.new(text)
      end

      # Styled text
      #
      # @since 1.3.0
      class StyledText
        def initialize(text, escape_code = nil)
          @text = text
          @escape_code = escape_code
        end

        # Makes `StyledText` printable
        #
        # @since 1.3.0
        def to_s
          text + escape_code
        end

        # since 1.3.0
        def bold
          chainable_update!(BOLD, text)
        end

        # since 1.3.0
        def dim
          chainable_update!(DIM, text)
        end

        # since 1.3.0
        def italic
          chainable_update!(ITALIC, text)
        end

        # since 1.3.0
        def underline
          chainable_update!(UNDERLINE, text)
        end

        # since 1.3.0
        def blink
          chainable_update!(BLINK, text)
        end

        # since 1.3.0
        def reverse
          chainable_update!(REVERSE, text)
        end

        # since 1.3.0
        def invisible
          chainable_update!(INVISIBLE, text)
        end

        # since 1.3.0
        def black
          chainable_update!(BLACK, text)
        end

        # since 1.3.0
        def red
          chainable_update!(RED, text)
        end

        # since 1.3.0
        def green
          chainable_update!(GREEN, text)
        end

        # since 1.3.0
        def yellow
          chainable_update!(YELLOW, text)
        end

        # since 1.3.0
        def blue
          chainable_update!(BLUE, text)
        end

        # since 1.3.0
        def magenta
          chainable_update!(MAGENTA, text)
        end

        # since 1.3.0
        def cyan
          chainable_update!(CYAN, text)
        end

        # since 1.3.0
        def white
          chainable_update!(WHITE, text)
        end

        # since 1.3.0
        def on_black
          chainable_update!(ON_BLACK, text)
        end

        # since 1.3.0
        def on_red
          chainable_update!(ON_RED, text)
        end

        # since 1.3.0
        def on_green
          chainable_update!(ON_GREEN, text)
        end

        # since 1.3.0
        def on_yellow
          chainable_update!(ON_YELLOW, text)
        end

        # since 1.3.0
        def on_blue
          chainable_update!(ON_BLUE, text)
        end

        # since 1.3.0
        def on_magenta
          chainable_update!(ON_MAGENTA, text)
        end

        # since 1.3.0
        def on_cyan
          chainable_update!(ON_CYAN, text)
        end

        # since 1.3.0
        def on_white
          chainable_update!(ON_WHITE, text)
        end

        private

        attr_reader :text, :escape_code

        # @since 1.3.0
        # @api private
        def chainable_update!(style, new_text)
          StyledText.new(
            select_graphic_rendition(style) + new_text,
            select_graphic_rendition(RESET)
          )
        end

        # @since 1.3.0
        # @api private
        def select_graphic_rendition(code)
          "\e[#{code}m"
        end
      end
    end
  end
end
