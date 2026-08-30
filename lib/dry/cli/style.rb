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
    # Building a style and applying it are always separate steps. For a one-off, apply it
    # straight away with `#[]`.
    #
    # @example
    #   Dry::CLI::Style.bold.red["Boom"] # => "\e[1;31mBoom\e[0m"
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
      require_relative "style/text"

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

      # @api private
      Unchecked = Object.new.freeze
      private_constant :Unchecked

      @enabled = nil
      @color_level = nil

      # Memoized values
      @env_enabled = Unchecked
      @detected_level = nil
      @checked_stdout = nil
      @stdout_enabled = nil

      class << self
        # Enable or disable styling for the whole program
        #
        # Set to `nil` (the default) to decide automatically: styling is on when the stream
        # being written to is a terminal and `NO_COLOR` is unset. `FORCE_COLOR` overrides both.
        #
        # @param enabled [TrueClass,FalseClass,NilClass]
        #
        # @example
        #   Dry::CLI::Style.enabled = false if args[:no_color]
        #
        # @api public
        # @since x.y.z
        def enabled=(enabled)
          @enabled = enabled
          forget_environment
        end

        # Whether styling is currently enabled for the program's own output
        #
        # Each stream decides this for itself as it renders, so this is the answer for
        # `$stdout`: what we fall back to for text written somewhere we don't know about.
        #
        # @return [TrueClass,FalseClass]
        #
        # @api public
        # @since x.y.z
        def enabled?
          out = $stdout
          return @stdout_enabled if @checked_stdout.equal?(out)

          @checked_stdout = out
          @stdout_enabled = enabled_for?(out)
        end

        # Whether styling is enabled for the given stream
        #
        # @param stream [IO]
        #
        # @return [TrueClass,FalseClass]
        #
        # @api private
        def enabled_for?(stream)
          enabled = @enabled
          return enabled unless enabled.nil?

          from_env = env_enabled
          return from_env unless from_env.nil?

          stream.respond_to?(:tty?) && stream.tty?
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
          forget_environment
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

          @color_level || detected_level
        end

        # How much color to render for the given stream, or `nil` for no styling at all
        #
        # An explicit {Dry::CLI::Style.enabled=} or {Dry::CLI::Style.color_level=} wins over
        # anything we would work out ourselves, which is what makes a `--color=always` of your
        # own reach a stream we would otherwise leave plain.
        #
        # @param stream [IO]
        #
        # @return [Symbol,NilClass]
        #
        # @api private
        def level_for(stream)
          return nil unless enabled_for?(stream)

          @color_level || detected_level
        end

        # How much color to render when we don't know which stream the text is bound for
        #
        # Answers for `$stdout`, which keeps this conservative: text we can't place is more
        # use plain in a file than colored in one.
        #
        # @return [Symbol,NilClass]
        #
        # @api private
        def default_level
          return nil unless enabled?

          @color_level || detected_level
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

        private

        # Returns whether an explicit env var has turned styling on or off.
        def env_enabled
          return @env_enabled unless @env_enabled.eql?(Unchecked)

          @env_enabled = detect_env_enabled
        end

        def detect_env_enabled
          return false unless ENV.fetch("NO_COLOR", "").empty?

          forced = ENV["FORCE_COLOR"]
          return !%w[0 false].include?(forced.downcase) unless forced.nil?

          nil
        end

        # Returns the color level a terminal can support, based on the environment.
        def detected_level
          @detected_level ||= ColorLevel.detect
        end

        def forget_environment
          @env_enabled = Unchecked
          @detected_level = nil
          @checked_stdout = nil
        end
      end

      # @api private
      attr_reader :steps

      # Returns a new style.
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

      # The style builder methods.
      #
      # This module is both included and extended on {Style}, which makes its builder methods
      # available to both begin and extend chains of styles.
      #
      # @api public
      module Builders
        # @!method bold
        # @!method dim
        # @!method italic
        # @!method underline
        # @!method blink
        # @!method reverse
        # @!method invisible
        # @!method black
        # @!method red
        # @!method green
        # @!method yellow
        # @!method blue
        # @!method magenta
        # @!method cyan
        # @!method white
        # @!method bright_black
        # @!method bright_red
        # @!method bright_green
        # @!method bright_yellow
        # @!method bright_blue
        # @!method bright_magenta
        # @!method bright_cyan
        # @!method bright_white
        # @!method on_black
        # @!method on_red
        # @!method on_green
        # @!method on_yellow
        # @!method on_blue
        # @!method on_magenta
        # @!method on_cyan
        # @!method on_white
        # @!method on_bright_black
        # @!method on_bright_red
        # @!method on_bright_green
        # @!method on_bright_yellow
        # @!method on_bright_blue
        # @!method on_bright_magenta
        # @!method on_bright_cyan
        # @!method on_bright_white
        #
        #   Adds this style to the chain.
        #
        #   Returns a new {Dry::CLI::Style}, to keep chaining or to apply with {#call} or {#[]}.
        #
        #   @return [Dry::CLI::Style]
        #
        #   @api public
        #   @since x.y.z

        ATTRIBUTES.each do |name, code|
          attribute = Attribute.new(name, code)

          define_method(name) do
            add(attribute)
          end
        end

        COLORS.each do |name, index|
          {name => index, :"bright_#{name}" => index + 8}.each do |color_name, color_index|
            {foreground: color_name, background: :"on_#{color_name}"}.each do |layer, method_name|
              color = Color::ANSI.new(layer, color_index, color_name)

              define_method(method_name) do
                add(color)
              end
            end
          end
        end

        # Adds a 24-bit color to the chain, degrading it to fit the terminal
        #
        # @param red [Integer] 0-255
        # @param green [Integer] 0-255
        # @param blue [Integer] 0-255
        #
        # @return [Dry::CLI::Style]
        #
        # @raise [Dry::CLI::InvalidColorError] if a component is out of range
        #
        # @example
        #   Dry::CLI::Style.rgb(255, 0, 0).call("Boom")
        #
        # @api public
        # @since x.y.z
        def rgb(red, green, blue)
          add(Color::RGB.new(:foreground, *Style.validate_components(red, green, blue)))
        end

        # Adds a 24-bit background color to the chain, degrading it to fit the terminal
        #
        # @param (see #rgb)
        #
        # @return (see #rgb)
        #
        # @raise (see #rgb)
        #
        # @example
        #   Dry::CLI::Style.on_rgb(255, 0, 0).call("Boom")
        #
        # @api public
        # @since x.y.z
        def on_rgb(red, green, blue)
          add(Color::RGB.new(:background, *Style.validate_components(red, green, blue)))
        end

        # Adds a 24-bit color written as hex to the chain, degrading it to fit the terminal
        #
        # @param value [String] a hex color, with or without its leading `#`, in three or six
        #   digits
        #
        # @return [Dry::CLI::Style]
        #
        # @raise [Dry::CLI::InvalidColorError] if the value isn't a hex color
        #
        # @example
        #   Dry::CLI::Style.hex("#ff0000").call("Boom")
        #   Dry::CLI::Style.hex("f00").call("Boom")
        #
        # @api public
        # @since x.y.z
        def hex(value)
          add(Color::RGB.new(:foreground, *Style.parse_hex(value)))
        end

        # Adds a 24-bit background color written as hex to the chain, degrading it to fit the
        # terminal
        #
        # @param (see #hex)
        #
        # @return (see #hex)
        #
        # @raise (see #hex)
        #
        # @example
        #   Dry::CLI::Style.on_hex("#ff0000").call("Boom")
        #
        # @api public
        # @since x.y.z
        def on_hex(value)
          add(Color::RGB.new(:background, *Style.parse_hex(value)))
        end

        # Adds a color from the 256 color palette to the chain, degrading it to fit the terminal
        #
        # @param index [Integer] a color code, 0-255
        #
        # @return [Dry::CLI::Style]
        #
        # @raise [Dry::CLI::InvalidColorError] if the code is out of range
        #
        # @example
        #   Dry::CLI::Style.ansi256(196).call("Boom")
        #
        # @api public
        # @since x.y.z
        def ansi256(index)
          add(Color::Xterm.new(:foreground, Style.validate_index(index)))
        end

        # Adds a background color from the 256 color palette to the chain, degrading it to fit
        # the terminal
        #
        # @param (see #ansi256)
        #
        # @return (see #ansi256)
        #
        # @raise (see #ansi256)
        #
        # @example
        #   Dry::CLI::Style.on_ansi256(196).call("Boom")
        #
        # @api public
        # @since x.y.z
        def on_ansi256(index)
          add(Color::Xterm.new(:background, Style.validate_index(index)))
        end
      end

      include Builders
      extend Builders

      # Starts a chain from a class-level style method
      #
      # This is the class-level counterpart of the private `#add` below, and the only piece
      # {Builders} needs to serve both the class and its instances.
      #
      # @api private
      private_class_method def self.add(step)
        new([step])
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
        Text.new([[self, text]])
      end

      # Renders the given text at the given color level
      #
      # @param text [String] the text to style
      # @param level [Symbol,NilClass] a color level, or `nil` for no styling at all
      #
      # @return [String]
      #
      # @api private
      def render(text, level)
        text = text.to_s
        return Style.unstyle(text) if level.nil?

        opening = sequence_for(level)
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
