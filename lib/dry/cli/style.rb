# frozen_string_literal: true

module Dry
  class CLI
    # A text style you can build up and reuse
    #
    # A style is a value. Build one by chaining style names, give it a name that means
    # something, then apply it to text as often as you like.
    #
    # @example
    #   ERROR = Dry::CLI::Style.bold.red
    #
    #   ERROR.call("Boom") # => "\e[1;31mBoom\e[0m"
    #
    # Each style name also accepts the text directly, for one-off styling.
    #
    # @example
    #   Dry::CLI::Style.bold.red("Boom") # => "\e[1;31mBoom\e[0m"
    #
    # ## Color
    #
    # Write the color you want and let it degrade. You build a style from 24-bit colors. We
    # turn it into escape sequences only when you apply it, when we know what the terminal can
    # show. If it cannot show a color, we swap in the closest one it can.
    #
    # @example
    #   ERROR = Dry::CLI::Style.bold.rgb(255, 0, 0)
    #
    #   ERROR.call("Boom")
    #   # on a 24-bit terminal  => "\e[1;38;2;255;0;0mBoom\e[0m"
    #   # on a 256 color one   => "\e[1;38;5;196mBoom\e[0m"
    #   # on a 16 color one    => "\e[1;91mBoom\e[0m"
    #   # on an 8 color one    => "\e[1;31mBoom\e[0m"
    #   # with no color at all => "\e[1mBoom\e[0m"
    #
    # The style holds the color, not the escape sequence, so one constant serves every
    # terminal: define it once when your program loads, and each terminal shows the best version
    # it can.
    #
    # Every name here with `color` in it has a `colour` alias, so spell it either way.
    #
    # @api public
    # @since x.y.z
    class Style
      require_relative "style/palette"
      require_relative "style/attribute"
      require_relative "style/color"
      require_relative "style/color_level"

      # ANSI escape sequence resetting all styles
      #
      # @api private
      RESET = "\e[0m"

      # Pattern matching the ANSI escape sequences we emit
      #
      # @api private
      SGR_PATTERN = /\e\[[0-9;]*m/

      # Non-color style names mapped to their ANSI code
      #
      # @api private
      ATTRIBUTES = {
        bold: 1,
        dim: 2,
        italic: 3,
        underline: 4,
        blink: 5,
        reverse: 7,
        invisible: 8
      }.freeze

      # Color names, and where they sit in the ANSI palette
      #
      # Each has a `bright_` version too, eight places along.
      #
      # @api private
      COLORS = {
        black: 0,
        red: 1,
        green: 2,
        yellow: 3,
        blue: 4,
        magenta: 5,
        cyan: 6,
        white: 7
      }.freeze

      # Pattern matching a hex color, with or without its leading `#`
      #
      # @api private
      HEX_PATTERN = /\A#?(?<digits>\h{3}|\h{6})\z/

      # The values an RGB component can take
      #
      # @api private
      COMPONENT_RANGE = (0..255)

      @enabled = nil
      @color_level = nil

      class << self
        # Enable or disable styling for the whole program
        #
        # Set to `nil` (the default) to decide automatically: styling is on when the program
        # writes to a terminal and `NO_COLOR` is unset. `FORCE_COLOR` overrides both.
        #
        # @param enabled [TrueClass,FalseClass,NilClass]
        #
        # @example
        #   Dry::CLI::Style.enabled = false if args[:no_color]
        #
        # @api public
        # @since x.y.z
        attr_writer :enabled

        # Whether styling is currently enabled
        #
        # @return [TrueClass,FalseClass]
        #
        # @api public
        # @since x.y.z
        def enabled?
          enabled = @enabled
          return enabled unless enabled.nil?

          return false unless ENV.fetch("NO_COLOR", "").empty?

          forced = ENV["FORCE_COLOR"]
          return !%w[0 false].include?(forced.downcase) unless forced.nil?

          $stdout.tty?
        end

        # Set how much color styles should render with
        #
        # Set to `nil` (the default) to decide automatically from the environment. Set it
        # explicitly to honour a `--color` flag of your own, or to pin the output in tests.
        #
        # @param level [Symbol,NilClass] `:truecolor`, `:ansi256`, `:ansi16`, `:ansi8`, `:none`
        #
        # @raise [ArgumentError] if the level isn't one we know
        #
        # @example
        #   Dry::CLI::Style.color_level = :truecolor
        #
        # @api public
        # @since x.y.z
        def color_level=(level)
          unless level.nil? || ColorLevel.valid?(level)
            raise ArgumentError,
              "unknown color level #{level.inspect}; " \
              "expected one of #{ColorLevel::ALL.map(&:inspect).join(', ')}, or nil"
          end

          @color_level = level
        end

        # How much color styles will currently render with
        #
        # @return [Symbol] one of `:truecolor`, `:ansi256`, `:ansi16`, `:ansi8`, `:none`
        #
        # @example
        #   Dry::CLI::Style.color_level # => :truecolor
        #
        # @api public
        # @since x.y.z
        def color_level
          return ColorLevel::NONE unless enabled?

          @color_level || ColorLevel.detect
        end

        # Remove all style escape sequences from the given text
        #
        # @param text [String] the text to strip
        #
        # @return [String] the text without styling
        #
        # @example
        #   Dry::CLI::Style.unstyle("\e[31mBoom\e[0m") # => "Boom"
        #
        # @api public
        # @since x.y.z
        def unstyle(text)
          text.to_s.gsub(SGR_PATTERN, "")
        end
      end

      # @api private
      attr_reader :steps

      # Returns a new style
      #
      # A style with no steps returns text unchanged. It's useful as a neutral value.
      #
      # @param steps [Array] the attributes and colors to apply
      #
      # @api private
      def initialize(steps = [])
        @steps = steps.freeze
        # Rendering a color means searching a palette for the closest match, so we keep each
        # level's sequence once we have worked it out. Most programs ask for only one.
        @sequences = {}
        freeze
      end

      # @!method bold(text = nil)
      # @!method dim(text = nil)
      # @!method italic(text = nil)
      # @!method underline(text = nil)
      # @!method blink(text = nil)
      # @!method reverse(text = nil)
      # @!method invisible(text = nil)
      # @!method black(text = nil)
      # @!method red(text = nil)
      # @!method green(text = nil)
      # @!method yellow(text = nil)
      # @!method blue(text = nil)
      # @!method magenta(text = nil)
      # @!method cyan(text = nil)
      # @!method white(text = nil)
      # @!method bright_black(text = nil)
      # @!method bright_red(text = nil)
      # @!method bright_green(text = nil)
      # @!method bright_yellow(text = nil)
      # @!method bright_blue(text = nil)
      # @!method bright_magenta(text = nil)
      # @!method bright_cyan(text = nil)
      # @!method bright_white(text = nil)
      # @!method on_black(text = nil)
      # @!method on_red(text = nil)
      # @!method on_green(text = nil)
      # @!method on_yellow(text = nil)
      # @!method on_blue(text = nil)
      # @!method on_magenta(text = nil)
      # @!method on_cyan(text = nil)
      # @!method on_white(text = nil)
      # @!method on_bright_black(text = nil)
      # @!method on_bright_red(text = nil)
      # @!method on_bright_green(text = nil)
      # @!method on_bright_yellow(text = nil)
      # @!method on_bright_blue(text = nil)
      # @!method on_bright_magenta(text = nil)
      # @!method on_bright_cyan(text = nil)
      # @!method on_bright_white(text = nil)
      #
      #   Adds this style to the chain.
      #
      #   Given text, applies the style and returns a `String`. Given nothing, returns a new
      #   {Dry::CLI::Style} to keep chaining.
      #
      #   @param text [String,nil] the text to style
      #
      #   @return [Dry::CLI::Style,String]
      #
      #   @api public
      #   @since x.y.z
      #
      # When adding styles, keep the signature of these methods stable:
      #
      # - The single positional argument is always the text. Never give it another meaning.
      # - Every styling parameter is a keyword, so it can't be mistaken for the text.
      # - Prefer a new style name over a parameter (`bright_red`, not `red(bright: true)`).
      # - Methods taking style _values_ (an RGB triplet, a 256-color code) fill the positional
      #   slots with those values, so they don't take text. Chain `#call` instead.
      ATTRIBUTES.each do |name, code|
        attribute = Attribute.new(name, code)

        define_method(name) do |text = nil|
          styled = add(attribute)
          text.nil? ? styled : styled.call(text)
        end

        define_singleton_method(name) do |text = nil|
          new.public_send(name, text)
        end
      end

      COLORS.each do |name, index|
        {name => index, :"bright_#{name}" => index + 8}.each do |color_name, color_index|
          {foreground: color_name, background: :"on_#{color_name}"}.each do |layer, method_name|
            color = Color::Ansi.new(layer, color_index, color_name)

            define_method(method_name) do |text = nil|
              styled = add(color)
              text.nil? ? styled : styled.call(text)
            end

            define_singleton_method(method_name) do |text = nil|
              new.public_send(method_name, text)
            end
          end
        end
      end

      # @!method rgb(red, green, blue)
      # @!method on_rgb(red, green, blue)
      #
      #   Adds a 24-bit color to the chain, degrading it to fit the terminal.
      #
      #   @param red [Integer] 0-255
      #   @param green [Integer] 0-255
      #   @param blue [Integer] 0-255
      #
      #   @return [Dry::CLI::Style]
      #
      #   @raise [Dry::CLI::InvalidColorError] if a component is out of range
      #
      #   @example
      #     Dry::CLI::Style.rgb(255, 0, 0).call("Boom")
      #
      #   @api public
      #   @since x.y.z
      {foreground: :rgb, background: :on_rgb}.each do |layer, method_name|
        define_method(method_name) do |red, green, blue|
          add(Color::RGB.new(layer, *Style.validate_components(red, green, blue)))
        end

        define_singleton_method(method_name) do |red, green, blue|
          new.public_send(method_name, red, green, blue)
        end
      end

      # @!method hex(value)
      # @!method on_hex(value)
      #
      #   Adds a 24-bit color written as hex to the chain, degrading it to fit the terminal.
      #
      #   @param value [String] a hex color, with or without its leading `#`, in three or six
      #     digits
      #
      #   @return [Dry::CLI::Style]
      #
      #   @raise [Dry::CLI::InvalidColorError] if the value isn't a hex color
      #
      #   @example
      #     Dry::CLI::Style.hex("#ff0000").call("Boom")
      #     Dry::CLI::Style.hex("f00").call("Boom")
      #
      #   @api public
      #   @since x.y.z
      {foreground: :hex, background: :on_hex}.each do |layer, method_name|
        define_method(method_name) do |value|
          add(Color::RGB.new(layer, *Style.parse_hex(value)))
        end

        define_singleton_method(method_name) do |value|
          new.public_send(method_name, value)
        end
      end

      # @!method ansi256(index)
      # @!method on_ansi256(index)
      #
      #   Adds a color from the 256 color palette to the chain, degrading it to fit the
      #   terminal.
      #
      #   @param index [Integer] a color code, 0-255
      #
      #   @return [Dry::CLI::Style]
      #
      #   @raise [Dry::CLI::InvalidColorError] if the code is out of range
      #
      #   @example
      #     Dry::CLI::Style.ansi256(196).call("Boom")
      #
      #   @api public
      #   @since x.y.z
      {foreground: :ansi256, background: :on_ansi256}.each do |layer, method_name|
        define_method(method_name) do |index|
          add(Color::Xterm.new(layer, Style.validate_index(index)))
        end

        define_singleton_method(method_name) do |index|
          new.public_send(method_name, index)
        end
      end

      # Applies the style to the given text
      #
      # We render colors at whatever level the terminal supports, so one style gives different
      # escape sequences on different terminals. When styling is off, returns the text with any
      # styling stripped out.
      #
      # @param text [String] the text to style
      #
      # @return [String] the styled text
      #
      # @example
      #   ERROR = Dry::CLI::Style.bold.red
      #
      #   ERROR.call("Boom") # => "\e[1;31mBoom\e[0m"
      #   ERROR["Boom"]      # => "\e[1;31mBoom\e[0m"
      #
      # @api public
      # @since x.y.z
      def call(text)
        text = text.to_s
        return self.class.unstyle(text) unless self.class.enabled?

        opening = sequence_for(self.class.color_level)
        return text if opening.empty?

        # Reopen our own sequence after any nested reset, so you can nest styled text
        "#{opening}#{text.gsub(RESET, RESET + opening)}#{RESET}"
      end
      alias_method :[], :call

      # Returns the style as a proc, for use with `&`
      #
      # @return [Proc]
      #
      # @example
      #   names.map(&Dry::CLI::Style.bold)
      #
      # @api public
      # @since x.y.z
      def to_proc
        method(:call).to_proc
      end

      # Returns the ANSI codes this style renders as at the given color level
      #
      # @param level [Symbol] a color level; defaults to the one currently in effect
      #
      # @return [Array<Integer>]
      #
      # @api private
      def codes(level = self.class.color_level)
        steps.flat_map { |step| step.codes(level) }
      end

      # @api private
      def ==(other)
        other.is_a?(self.class) && other.steps == steps
      end
      alias_method :eql?, :==

      # @api private
      def hash
        [self.class, steps].hash
      end

      # @api private
      def inspect
        return "#<#{self.class.name}>" if steps.empty?

        "#<#{self.class.name} #{steps.map(&:to_s).join(".")}>"
      end

      # @api private
      def self.validate_components(*components)
        components.each do |component|
          next if component.is_a?(Integer) && COMPONENT_RANGE.cover?(component)

          raise InvalidColorError.new(
            value: component,
            expected: "an integer between 0 and 255"
          )
        end
      end

      # @api private
      def self.validate_index(index)
        unless index.is_a?(Integer) && COMPONENT_RANGE.cover?(index)
          raise InvalidColorError.new(
            value: index,
            expected: "a color code between 0 and 255"
          )
        end

        index
      end

      # @api private
      def self.parse_hex(value)
        digits = HEX_PATTERN.match(value.to_s)&.[](:digits)

        if digits.nil?
          raise InvalidColorError.new(value: value, expected: %(a hex color, like "#ff0000"))
        end

        digits = digits.chars.flat_map { |digit| [digit, digit] }.join if digits.length == 3
        digits.scan(/\h{2}/).map { |pair| pair.to_i(16) }
      end

      private

      def add(step)
        self.class.new(steps + [step])
      end

      def sequence_for(level)
        @sequences[level] ||= begin
          codes = codes(level)
          codes.empty? ? "" : "\e[#{codes.join(";")}m"
        end
      end
    end
  end
end
