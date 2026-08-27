# frozen_string_literal: true

module Dry
  class CLI
    class Style
      # The colors a terminal can show, and how to find the closest one
      #
      # A style holds 24-bit colors. When we apply it, we swap each color for the nearest one
      # the terminal can show. This module holds the palettes we swap in, and the search that
      # picks from them.
      #
      # @since 1.5.0
      # @api private
      module Palette
        # The 16 ANSI colors, with the values xterm gives them
        #
        # Codes 0-7 are the base colors, 8-15 the bright ones. Users can change these in their
        # terminal settings, so we use the values to find the closest match, not to say what the
        # screen will show.
        #
        # @since 1.5.0
        # @api private
        ANSI = [
          [0, 0, 0],       # black
          [128, 0, 0],     # red
          [0, 128, 0],     # green
          [128, 128, 0],   # yellow
          [0, 0, 128],     # blue
          [128, 0, 128],   # magenta
          [0, 128, 128],   # cyan
          [192, 192, 192], # white
          [128, 128, 128], # bright_black
          [255, 0, 0],     # bright_red
          [0, 255, 0],     # bright_green
          [255, 255, 0],   # bright_yellow
          [0, 0, 255],     # bright_blue
          [255, 0, 255],   # bright_magenta
          [0, 255, 255],   # bright_cyan
          [255, 255, 255]  # bright_white
        ].freeze

        # The six levels each of red, green and blue takes in the 6x6x6 color cube
        #
        # @since 1.5.0
        # @api private
        CUBE_STEPS = [0, 95, 135, 175, 215, 255].freeze

        # The 256 color palette, as red, green and blue values by color code
        #
        # Codes 0-15 are {ANSI}, 16-231 a 6x6x6 color cube, and 232-255 24 shades of gray.
        #
        # @since 1.5.0
        # @api private
        XTERM = [
          *ANSI,
          *CUBE_STEPS.product(CUBE_STEPS, CUBE_STEPS),
          *(0...24).map { |step| Array.new(3, 8 + (step * 10)) }
        ].map(&:freeze).freeze

        # The first color code we search when we degrade a 24-bit color
        #
        # Users can change codes 0-15 in their terminal settings. If someone has set their "red"
        # to a pastel, we should not answer `rgb(255, 0, 0)` with that pastel, so we search from
        # 16 up, where the codes have fixed values.
        #
        # @since 1.5.0
        # @api private
        FIXED_RANGE = (16..255)

        # The ANSI colors that have a hue, and the ones that are only gray
        #
        # @since 1.5.0
        # @api private
        CHROMATIC = [*1..6, *9..14].freeze

        # @since 1.5.0
        # @api private
        GRAYS = [0, 7, 8, 15].freeze

        # @since 1.5.0
        # @api private
        BASE_CHROMATIC = [*1..6].freeze

        # @since 1.5.0
        # @api private
        BASE_GREYS = [0, 7].freeze

        # How much color a shade needs before we match its hue instead of its brightness
        #
        # With 16 colors to pick from, often none is close to the one you asked for, and the
        # closest by distance is a gray. A mid violet is nearer to gray than to any purple in the
        # palette. Gray is the right answer by the sums and the wrong one on screen: a style says
        # "this is an error" or "this is a warning", and it says it with hue. So we first ask
        # whether the color has a hue worth keeping, then match it only against colors that
        # keep it.
        #
        # We measure that as chroma, the gap between the highest and lowest of red, green and
        # blue. Saturation would be wrong here. It runs high for any dark color, so it would
        # turn near blacks into whatever hue their few stray levels tilt toward.
        #
        # @since 1.5.0
        # @api private
        CHROMA_THRESHOLD = 48

        class << self
          # Returns the RGB triplet for a 256 color code
          #
          # @param code [Integer] a color code, 0-255
          #
          # @return [Array<Integer>] the red, green and blue components
          #
          # @since 1.5.0
          # @api private
          def rgb(code)
            XTERM.fetch(code)
          end

          # Returns the closest 256 color code to the given color
          #
          # @param red [Integer]
          # @param green [Integer]
          # @param blue [Integer]
          #
          # @return [Integer] a color code, 16-255
          #
          # @since 1.5.0
          # @api private
          def nearest_xterm(red, green, blue)
            nearest(FIXED_RANGE, red, green, blue)
          end

          # Returns the closest of the 16 ANSI colors to the given color
          #
          # @param red [Integer]
          # @param green [Integer]
          # @param blue [Integer]
          #
          # @return [Integer] a color code, 0-15
          #
          # @since 1.5.0
          # @api private
          def nearest_ansi(red, green, blue)
            candidates = chromatic?(red, green, blue) ? CHROMATIC : GRAYS

            nearest(candidates, red, green, blue)
          end

          # Returns the closest of the 8 base ANSI colors to the given color
          #
          # @param red [Integer]
          # @param green [Integer]
          # @param blue [Integer]
          #
          # @return [Integer] a color code, 0-7
          #
          # @since 1.5.0
          # @api private
          def nearest_base_ansi(red, green, blue)
            candidates = chromatic?(red, green, blue) ? BASE_CHROMATIC : BASE_GREYS

            nearest(candidates, red, green, blue)
          end

          private

          # Returns whether the color has a hue worth keeping
          #
          # @since 1.5.0
          # @api private
          def chromatic?(red, green, blue)
            components = [red, green, blue]

            (components.max - components.min) >= CHROMA_THRESHOLD
          end

          # Returns the code within the range whose color is closest to the given one
          #
          # @since 1.5.0
          # @api private
          def nearest(range, red, green, blue)
            range.min_by { |code| distance(XTERM[code], red, green, blue) }
          end

          # Returns how far apart two colors look, squared
          #
          # Plain distance in red, green and blue treats all three as equal. The eye does not. It
          # sees a shift in green more than one in blue, and it sees red differently in dark
          # colors than in light ones. This is the "redmean" formula, which weights the three to
          # match. It is close enough to pick good matches, and it costs almost nothing.
          #
          # We compare squared distances, since sorting by a distance and by its square gives the
          # same order.
          #
          # @see https://www.compuphase.com/cmetric.htm
          #
          # @since 1.5.0
          # @api private
          def distance(reference, red, green, blue)
            mean = (reference[0] + red) / 2
            delta_red = reference[0] - red
            delta_green = reference[1] - green
            delta_blue = reference[2] - blue

            (((512 + mean) * delta_red * delta_red) >> 8) +
              (4 * delta_green * delta_green) +
              (((767 - mean) * delta_blue * delta_blue) >> 8)
          end
        end
      end
    end
  end
end
