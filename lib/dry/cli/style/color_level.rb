# frozen_string_literal: true

module Dry
  class CLI
    class Style
      # How much color is supported by a terminal.
      #
      # There is no way to ask a terminal what it can do, so we go by what it sets in the
      # environment: `COLORTERM` and the `TERM` name.
      #
      # When we cannot infer a terminal's color support, we degrade to basic {ANSI16}.
      #
      # Override the color level by setting `FORCE_COLOR` or {Dry::CLI::Style.color_level=}.
      #
      # @api private
      module ColorLevel
        # No color at all.
        NONE = :none

        # The 8 base ANSI colors.
        ANSI8 = :ansi8

        # The 8 base ANSI colors plus the bright ones.
        ANSI16 = :ansi16

        # The 256 color palette.
        ANSI256 = :ansi256

        # 24-bit color.
        TRUECOLOR = :truecolor

        # Every level, from least color to most.
        ALL = [NONE, ANSI8, ANSI16, ANSI256, TRUECOLOR].freeze

        # The levels `FORCE_COLOR` can name, by the value it holds.
        #
        # Follows what other tools do with `FORCE_COLOR`: any value means "yes, color", and a digit
        # says how much.
        FORCED = {
          "0" => NONE,
          "false" => NONE,
          "1" => ANSI16,
          "2" => ANSI256,
          "3" => TRUECOLOR
        }.freeze

        # The `COLORTERM` values announcing 24-bit color.
        TRUECOLOR_COLORTERMS = %w[truecolor 24bit].freeze

        # The `TERM` fragments terminfo uses for a direct color terminal.
        TRUECOLOR_TERMS = %w[direct truecolor].freeze

        # The `TERM` suffixes terminfo uses for a 256 color terminal.
        ANSI256_TERMS = %w[-256color -256].freeze

        # The `TERM` values that rule out color.
        #
        # Names rather than terminals: `dumb` means a terminal that takes no escape sequences,
        # `unknown` one that terminfo has no entry for.
        COLORLESS_TERMS = %w[dumb unknown].freeze

        # Set by Windows Terminal, which sets no `TERM`.
        WINDOWS_TRUECOLOR = "WT_SESSION"

        class << self
          # Returns the color level of the terminal.
          #
          # @return [Symbol] one of {ALL}
          def detect(env = ENV)
            level = forced(env)
            return level if level

            term = env["TERM"].to_s.downcase
            return NONE if COLORLESS_TERMS.include?(term)

            return TRUECOLOR if truecolor?(env, term)
            return ANSI256 if term.end_with?(*ANSI256_TERMS)

            # If `TERM` is set to anything, assume the 16 colors every terminal has had since
            # the eighties. An empty `TERM` leaves us nothing to go on.
            return ANSI16 unless term.empty?

            NONE
          end

          # Returns whether the level is valid.
          def valid?(level)
            ALL.include?(level)
          end

          private

          # Returns the level `FORCE_COLOR` names, if it names one.
          #
          # A value we do not recognize still means "yes, color". We just have to work out how much
          # on our own, so we fall through to detection.
          def forced(env)
            value = env["FORCE_COLOR"]
            return nil if value.nil?

            FORCED[value.downcase]
          end

          def truecolor?(env, term)
            return true if TRUECOLOR_COLORTERMS.include?(env["COLORTERM"].to_s.downcase)
            return true if TRUECOLOR_TERMS.any? { |fragment| term.include?(fragment) }

            env.key?(WINDOWS_TRUECOLOR)
          end
        end
      end
    end
  end
end
