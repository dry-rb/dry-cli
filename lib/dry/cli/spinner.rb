# frozen_string_literal: true

module Dry
  class CLI
    # A generic spinner that you can use to define your own with a given frameset.
    #
    # @example A static message
    #   Dry::CLI::Spinner::Dot.run "%{spinner} Loading..." do
    #     # do something that takes time
    #   end
    #
    # @example Dynamically update the message on each tick
    #   deadline = Time.now + 30
    #
    #   format = Dry::CLI::Style.dim["Waiting "] +
    #     Dry::CLI::Style.bold["%{remaining}"] +
    #     Dry::CLI::Style.dim["s"]
    #
    #   Dry::CLI::Spinner::Line.run format do |s|
    #     s.before_tick do |_, data|
    #       data[:remaining] = (deadline - Time.now).ceil
    #     end
    #
    #     s.run do
    #       # do something that takes time
    #     end
    #   end
    #
    # @api public
    # @since x.y.z
    class Spinner < Data.define(:frames, :fps)
      # !@method initialize
      #   Returns a new Spinner.
      #
      #   @param frames [Enumerable<String>] The frames to cycle through for the spinner
      #   @param fps [Integer] The frames per second for the spinner
      #   @return [Dry::CLI::Spinner] A new Spinner instance
      #
      #   @api public

      # Start up a new Dry::CLI::Ticker that renders the spinner to a stream.
      #
      # Nothing is drawn when `stream` is not a terminal, but the block still runs.
      #
      # @param format [String, Dry::CLI::Style::Text] The format string for the spinner text. The spinner frame will be interpolated as a named reference `%{spinner}`.
      # @param fps [Integer] The frames per second for the spinner. Defaults to the spinner's fps.
      # @param stream [IO, Dry::CLI::Stream] The stream to render the spinner to.
      #
      # @yieldparam [Dry::CLI::Spinner::DSL] The block to configure the spinner's behavior.
      # rubocop:disable Metrics/AbcSize
      def run(format = "%{spinner}", fps: self.fps, stream: $stderr, &)
        require_relative "spinner/dsl"

        stream = Stream.for(stream)
        worker, before_tick, after_tick = DSL.new(&).handlers

        if stream.tty?
          require_relative "ticker"

          stream.raw.print ANSI.hide_cursor

          frames = self.frames.cycle

          ticker = Ticker.start(interval: 1.0 / fps) do
            stream.raw.print ANSI.erase_line

            data = {spinner: frames.next}
            before_tick.call(stream, data)

            stream.print format % data

            after_tick.call(stream)
          end
        end

        worker.call
      ensure
        cleanup(stream, ticker) if stream.tty?
      end
      # rubocop:enable Metrics/AbcSize

      # Dot Spinner variant
      Dot = new(frames: %w[⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽ ⣾], fps: 10)

      # Ellipsis Spinner variant
      Ellipsis = new(frames: ["", ".", "..", "..."], fps: 3)

      # Line Spinner variant
      Line = new(frames: %w[| / - \\], fps: 10)

      # MiniDot Spinner variant
      MiniDot = new(frames: %w[⠏ ⠇ ⠧ ⠦ ⠴ ⠼ ⠸ ⠹ ⠙ ⠋], fps: 12)

      private

      def cleanup(stream, ticker)
        ticker&.stop
        stream.raw.print ANSI.erase_line
      ensure
        stream.raw.print ANSI.show_cursor
      end
    end
  end
end
