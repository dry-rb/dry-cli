# frozen_string_literal: true

require "delegate"

module Dry
  class CLI
    # A stream for commands to write their output, which renders the styled text it is given.
    #
    # A stream is the only thing that knows both what is being written and what it can show, so it
    # is the thing that turns styles into escape sequences. Two streams from the one program can
    # answer differently, which is how a stream that has been redirected gets plain text while the
    # terminal beside it keeps its color.
    #
    # Everything else is passed to the stream underneath, so this behaves as the stream you gave us
    # in every other way. To write to it without any of this, see {#raw}.
    #
    # @api public
    # @since x.y.z
    class Stream < SimpleDelegator
      # Returns a stream that renders what is written to it.
      #
      # A stream we have already wrapped is given back as it is.
      #
      # @param stream [IO] the stream to write to
      #
      # @return [Dry::CLI::Stream]
      #
      # @api private
      def self.for(stream)
        stream.is_a?(self) ? stream : new(stream)
      end

      # @api private
      def puts(*args)
        # Nearly every write is one string, and going through the general case would build an array
        # to map over and another to spread back out again
        return __getobj__.puts(render_value(args[0])) if args.size == 1

        __getobj__.puts(*render(args))
      end

      # @api private
      def print(*args)
        return __getobj__.print(render_value(args[0])) if args.size == 1

        __getobj__.print(*render(args))
      end

      # @api private
      def write(*args)
        return __getobj__.write(render_value(args[0])) if args.size == 1

        __getobj__.write(*render(args))
      end

      # @api private
      def printf(format, *args)
        __getobj__.printf(render_value(format), *render(args))
      end

      # @api private
      def <<(text)
        __getobj__ << render_value(text)
        self
      end

      # The underlying stream, to write to directly.
      #
      # Everything written through this stream is rendered for it. If you need to control rendering
      # your self (such as displaying a progress bar), write to this raw stream.
      #
      # @example
      #   stdout.raw.print "\e[2K\r"
      #
      # @return [IO] the stream this one was made for
      #
      # @api public
      # @since x.y.z
      def raw
        __getobj__
      end

      # Returns true if the stream underneath is a terminal.
      #
      # This result is memoized so we can avoid a syscall (the actual `tty?` check) every time we
      # check {#color_level}.
      #
      # @return [Boolean]
      #
      # @api private
      def tty?
        # `false` is a legitimate value, so `||=` memoization would check again every time.
        return @tty unless @tty.nil?

        @tty = __getobj__.respond_to?(:tty?) && __getobj__.tty?
      end

      # How much color this stream can show, or `nil` when it should show none.
      #
      # @api private
      def color_level
        Style.color_level_for(self)
      end

      private

      def render(args)
        args.map { |arg| render_value(arg) }
      end

      # Styled text is rendered for this stream. A string has already been rendered by someone else,
      # so the most we can do is take styling out again when this stream can't show it — which
      # leaves a forced `--color=always` alone, because that gives us a color level to render at.
      def render_value(value)
        case value
        when Style::Text then value.render(color_level)
        when Array then value.map { |element| render_value(element) }
        when String
          # Most of what a program writes has no styling in it, so look before rewriting it:
          # searching for one character beats a scan for escape sequences that aren't there.
          color_level.nil? && value.include?(Style::ESCAPE) ? Style.unstyle(value) : value
        else value
        end
      end
    end
  end
end
