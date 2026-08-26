# frozen_string_literal: true

module Dry
  class CLI
    # A composable, reusable text style
    #
    # A style is a value. Build one by chaining style names, assign it a meaningful name,
    # then apply it to text as many times as you like.
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
    # @since 1.5.0
    class Style
      # ANSI escape sequence resetting all styles
      #
      # @since 1.5.0
      # @api private
      RESET = "\e[0m"

      # Pattern matching the ANSI escape sequences we emit
      #
      # @since 1.5.0
      # @api private
      SGR_PATTERN = /\e\[[0-9;]*m/

      # Style names mapped to their ANSI code
      #
      # @since 1.5.0
      # @api private
      CODES = {
        bold: 1,
        dim: 2,
        italic: 3,
        underline: 4,
        blink: 5,
        reverse: 7,
        invisible: 8,
        black: 30,
        red: 31,
        green: 32,
        yellow: 33,
        blue: 34,
        magenta: 35,
        cyan: 36,
        white: 37,
        on_black: 40,
        on_red: 41,
        on_green: 42,
        on_yellow: 43,
        on_blue: 44,
        on_magenta: 45,
        on_cyan: 46,
        on_white: 47
      }.freeze

      @enabled = nil

      class << self
        # Enable or disable styling for the whole program
        #
        # Set to `nil` (the default) to decide automatically: styling is on when the program
        # writes to a terminal and `NO_COLOR` is unset.
        #
        # @param enabled [TrueClass,FalseClass,NilClass]
        #
        # @example
        #   Dry::CLI::Style.enabled = false if args[:no_color]
        #
        # @since 1.5.0
        attr_writer :enabled

        # Whether styling is currently enabled
        #
        # @return [TrueClass,FalseClass]
        #
        # @since 1.5.0
        def enabled?
          enabled = @enabled
          return enabled unless enabled.nil?

          $stdout.tty? && ENV.fetch("NO_COLOR", "").empty?
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
        # @since 1.5.0
        def unstyle(text)
          text.to_s.gsub(SGR_PATTERN, "")
        end
      end

      # @since 1.5.0
      # @api private
      attr_reader :codes

      # Returns a new style
      #
      # A style with no codes returns text unchanged. It's useful as a neutral value.
      #
      # @param codes [Array<Integer>] the ANSI codes to apply
      #
      # @since 1.5.0
      # @api private
      def initialize(codes = [])
        @codes = codes.freeze
        @sequence = codes.empty? ? "" : "\e[#{codes.join(";")}m"
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
      # @!method on_black(text = nil)
      # @!method on_red(text = nil)
      # @!method on_green(text = nil)
      # @!method on_yellow(text = nil)
      # @!method on_blue(text = nil)
      # @!method on_magenta(text = nil)
      # @!method on_cyan(text = nil)
      # @!method on_white(text = nil)
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
      #   @since 1.5.0
      #
      # When adding styles, keep the signature of these methods stable:
      #
      # - The single positional argument is always the text. Never give it another meaning.
      # - Every styling parameter is a keyword, so it can't be mistaken for the text.
      # - Prefer a new style name over a parameter (`bright_red`, not `red(bright: true)`).
      # - Methods taking style _values_ (an RGB triplet, a 256-colour code) fill the positional
      #   slots with those values, so they don't take text. Chain `#call` instead.
      CODES.each do |name, code|
        define_method(name) do |text = nil|
          styled = self.class.new(codes + [code])
          text.nil? ? styled : styled.call(text)
        end

        define_singleton_method(name) do |text = nil|
          new.public_send(name, text)
        end
      end

      # Applies the style to the given text
      #
      # When styling is disabled, returns the text with any existing styling removed.
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
      # @since 1.5.0
      def call(text)
        text = text.to_s
        return self.class.unstyle(text) unless self.class.enabled?
        return text if codes.empty?

        # Reopen our own sequence after any nested reset, so styled text can be composed
        "#{@sequence}#{text.gsub(RESET, RESET + @sequence)}#{RESET}"
      end
      alias_method :[], :call

      # Returns the style as a proc, for use with `&`
      #
      # @return [Proc]
      #
      # @example
      #   names.map(&Dry::CLI::Style.bold)
      #
      # @since 1.5.0
      def to_proc
        method(:call).to_proc
      end

      # @since 1.5.0
      # @api private
      def ==(other)
        other.is_a?(self.class) && other.codes == codes
      end
      alias_method :eql?, :==

      # @since 1.5.0
      # @api private
      def hash
        [self.class, codes].hash
      end

      # @since 1.5.0
      # @api private
      def inspect
        "#<#{self.class.name} #{CODES.select { |_, code| codes.include?(code) }.keys.join(".")}>"
      end
    end
  end
end
