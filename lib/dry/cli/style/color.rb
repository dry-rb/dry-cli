# frozen_string_literal: true

require "dry/cli/style/color_level"
require "dry/cli/style/palette"

module Dry
  class CLI
    class Style
      # A color, and what it becomes on a terminal that cannot show it
      #
      # You write a color once, in whatever form suits you. We ask it for its ANSI codes later,
      # when we know what the terminal can show. Each subclass answers that in its own way:
      # {Ansi} always fits, {Xterm} drops to 16 or 8 colors, and {RGB} drops to any of them.
      #
      # @api private
      class Color
        EMPTY = [].freeze

        # The layer a color applies to, and the ANSI codes each layer starts from
        LAYERS = {
          foreground: {base: 30, bright: 90, extended: 38},
          background: {base: 40, bright: 100, extended: 48}
        }.freeze

        attr_reader :layer

        def initialize(layer)
          @layer = layer
        end

        # Returns the ANSI codes for this color at the given level
        #
        # @param level [Symbol] a {Dry::CLI::Style::ColorLevel}
        #
        # @return [Array<Integer>]
        def codes(_level)
          raise NotImplementedError
        end

        def ==(other)
          other.is_a?(self.class) && other.layer == layer && other.value == value
        end
        alias_method :eql?, :==

        def hash
          [self.class, layer, value].hash
        end

        def prefix
          layer == :background ? "on_" : ""
        end

        protected

        # The color's defining value, for comparison
        def value
          raise NotImplementedError
        end

        private

        # Returns the codes for one of the 16 ANSI colors on this layer
        #
        # @param index [Integer] a color code, 0-15
        def ansi_codes(index)
          offsets = LAYERS.fetch(layer)

          if index < 8
            [offsets[:base] + index]
          else
            [offsets[:bright] + (index - 8)]
          end
        end

        def extended_code
          LAYERS.fetch(layer)[:extended]
        end

        # One of the 16 ANSI colors
        #
        # Every terminal that shows color at all has these, so they never need to degrade. The
        # one exception is {ColorLevel::ANSI8}, which has no bright colors: there each bright
        # color drops to the base color it brightens. We do that on purpose rather than search
        # for the closest color. Someone who asks for `bright_black` wants black, not the light
        # gray that happens to sit nearest it among the eight.
        class Ansi < Color
          attr_reader :index, :name

          def initialize(layer, index, name)
            super(layer)
            @index = index
            @name = name
            freeze
          end

          def codes(level)
            case level
            when ColorLevel::NONE then EMPTY
            when ColorLevel::ANSI8 then ansi_codes(index % 8)
            else ansi_codes(index)
            end
          end

          def to_s
            "#{prefix}#{name}"
          end

          protected

          def value
            index
          end
        end

        # One of the 256 palette colors
        #
        # Terminals that show 24-bit color read the 256 color escapes too, so this only degrades
        # downward. To do that we look up the color's red, green and blue values, then find the
        # closest match among the 16 or 8 colors left.
        class Xterm < Color
          attr_reader :index

          def initialize(layer, index)
            super(layer)
            @index = index
            freeze
          end

          def codes(level)
            case level
            when ColorLevel::NONE then EMPTY
            when ColorLevel::TRUECOLOR, ColorLevel::ANSI256 then [extended_code, 5, index]
            else ansi_codes(nearest(level))
            end
          end

          def to_s
            "#{prefix}ansi256(#{index})"
          end

          protected

          def value
            index
          end

          private

          def nearest(level)
            red, green, blue = Palette.rgb(index)

            if level == ColorLevel::ANSI8
              Palette.nearest_base_ansi(red, green, blue)
            else
              Palette.nearest_ansi(red, green, blue)
            end
          end
        end

        # A 24-bit color
        #
        # This is the form you write most styles in, and the one that degrades furthest. Below
        # 24-bit we swap it for the closest color the terminal can show, taken from whatever
        # palette that level leaves us.
        #
        # @api private
        class RGB < Color
          attr_reader :red, :green, :blue

          def initialize(layer, red, green, blue)
            super(layer)
            @red = red
            @green = green
            @blue = blue
            freeze
          end

          def codes(level)
            case level
            when ColorLevel::NONE then EMPTY
            when ColorLevel::TRUECOLOR then [extended_code, 2, red, green, blue]
            when ColorLevel::ANSI256
              [extended_code, 5, Palette.nearest_xterm(red, green, blue)]
            when ColorLevel::ANSI16 then ansi_codes(Palette.nearest_ansi(red, green, blue))
            else ansi_codes(Palette.nearest_base_ansi(red, green, blue))
            end
          end

          def to_s
            "#{prefix}rgb(#{red}, #{green}, #{blue})"
          end

          protected

          def value
            [red, green, blue]
          end
        end
      end
    end
  end
end
