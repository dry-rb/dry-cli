# frozen_string_literal: true

module Dry
  class CLI
    # Collection of functions to style text.
    #
    # @since 1.3.0
    module Styles
      # since 1.3.0
      def bold(text)
        ensure_clean_sequence("\e[1m#{text}")
      end

      # since 1.3.0
      def dim(text)
        ensure_clean_sequence("\e[2m#{text}")
      end

      # since 1.3.0
      def italic(text)
        ensure_clean_sequence("\e[3m#{text}")
      end

      # since 1.3.0
      def underline(text)
        ensure_clean_sequence("\e[4m#{text}")
      end

      # since 1.3.0
      def blink(text)
        ensure_clean_sequence("\e[5m#{text}")
      end

      # since 1.3.0
      def reverse(text)
        ensure_clean_sequence("\e[7m#{text}")
      end

      # since 1.3.0
      def invisible(text)
        ensure_clean_sequence("\e[8m#{text}")
      end

      # since 1.3.0
      def black(text)
        ensure_clean_sequence("\e[30m#{text}")
      end

      # since 1.3.0
      def red(text)
        ensure_clean_sequence("\e[31m#{text}")
      end

      # since 1.3.0
      def green(text)
        ensure_clean_sequence("\e[32m#{text}")
      end

      # since 1.3.0
      def yellow(text)
        ensure_clean_sequence("\e[33m#{text}")
      end

      # since 1.3.0
      def blue(text)
        ensure_clean_sequence("\e[34m#{text}")
      end

      # since 1.3.0
      def magenta(text)
        ensure_clean_sequence("\e[35m#{text}")
      end

      # since 1.3.0
      def cyan(text)
        ensure_clean_sequence("\e[36m#{text}")
      end

      # since 1.3.0
      def white(text)
        ensure_clean_sequence("\e[37m#{text}")
      end

      # since 1.3.0
      def on_black(text)
        ensure_clean_sequence("\e[40m#{text}")
      end

      # since 1.3.0
      def on_red(text)
        ensure_clean_sequence("\e[41m#{text}")
      end

      # since 1.3.0
      def on_green(text)
        ensure_clean_sequence("\e[42m#{text}")
      end

      # since 1.3.0
      def on_yellow(text)
        ensure_clean_sequence("\e[43m#{text}")
      end

      # since 1.3.0
      def on_blue(text)
        ensure_clean_sequence("\e[44m#{text}")
      end

      # since 1.3.0
      def on_magenta(text)
        ensure_clean_sequence("\e[45m#{text}")
      end

      # since 1.3.0
      def on_cyan(text)
        ensure_clean_sequence("\e[46m#{text}")
      end

      # since 1.3.0
      def on_white(text)
        ensure_clean_sequence("\e[47m#{text}")
      end

      private

      # @since 1.3.0
      # @api private
      def ensure_clean_sequence(text)
        clen_text = text
        clear = "\e[0m"
        clen_text += clear unless text.end_with?(clear)
        clen_text
      end
    end
  end
end
