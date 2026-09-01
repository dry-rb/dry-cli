# frozen_string_literal: true

module Dry
  class CLI
    class Style
      # Text with styles attached, rendered when it is written to a {Dry::CLI::Stream}.
      #
      # Applying a style gives you one of these rather than a `String`. It holds the text and the
      # styles, and turns them into escape sequences at the last moment: when it reaches a stream,
      # which knows what it can show.
      #
      # This structure is what allows for writing colored text to a terminal but plain text to a
      # file it is redirected to. It also means the text knows how long it is without its escape
      # sequences, so padding lines up.
      #
      # @example
      #   ERROR = Dry::CLI::Style.bold.red
      #   ERROR["Boom"].length # => 4
      #
      # Anywhere a `String` is wanted, this renders itself for Ruby's own `$stdout`, so
      # interpolation, `format`, and `puts` all still work.
      #
      # @api public
      # @since x.y.z
      class Text
        # The runs of text this is made of, each with the style to render it in.
        #
        # Each part is a `[style, text]` pair, and they render in order and join together. A `nil`
        # style means that run is plain: joining styled text to a plain `String` keeps both, rather
        # than rendering early to make one `String` of them.
        #
        # @example
        #   (ERROR["failed"] + ": " + reason).parts
        #   # => [[#<Dry::CLI::Style bold.red>, "failed"],
        #   #     [nil, ": "],
        #   #     [nil, "no such file"]]
        #
        # A part's text can be another {Dry::CLI::Style::Text}, which is how a style wraps text that
        # is already styled. It renders from the inside out, so the outer style picks up again where
        # the inner one left off.
        #
        # @example
        #   Dry::CLI::Style.red[Dry::CLI::Style.bold["config.yml"]].parts
        #   # => [[#<Dry::CLI::Style red>, #<Dry::CLI::Style::Text "config.yml">]]
        #
        # @return [Array<Array(Dry::CLI::Style,String)>]
        #
        # @api private
        attr_reader :parts

        # @param parts [Array<Array(Dry::CLI::Style,String)>] the runs of text and their styles, in
        #   the order they render
        #
        # @api private
        def initialize(parts)
          @parts = parts.freeze
          freeze
        end

        # Returns the text rendered with styles for the given color level.
        #
        # @param color_level [Symbol, nil] a color level, or `nil` for no styling at all
        #
        # @return [String]
        #
        # @api private
        def render(color_level)
          return plain if color_level.nil?
          return render_part(*parts.first, color_level) if parts.one?

          parts.map { |style, text| render_part(style, text, color_level) }.join
        end

        # Returns the text on its own, with no styles applied.
        #
        # Use this as the fast path to render text when styling has been disabled.
        #
        # @return [String]
        #
        # @api private
        def plain
          return plain_text(parts.first.last) if parts.one?

          parts.map { |_style, text| plain_text(text) }.join
        end

        # Renders the text for Ruby's own `$stdout`.
        #
        # @return [String]
        #
        # @api public
        # @since x.y.z
        def to_s
          render(Style.default_stdout_color_level)
        end
        alias_method :to_str, :to_s

        # Joins this text to other text, keeping both sides unrendered.
        #
        # Only works this way around. With a `String` on the left, Ruby asks us for a `String` in
        # return, so `"read " + styled` renders there and then, for Ruby's own `$stdout` rather than
        # the stream it ends up on. Put the styled text first, or style the whole of it, and it
        # stays unrendered until it is written.
        #
        # @example
        #   ERROR["failed"] + ": " + reason # stays unrendered
        #   "failed: " + ERROR[reason]      # renders ERROR[reason] now
        #
        # @param other [Dry::CLI::Style::Text,String]
        #
        # @return [Dry::CLI::Style::Text]
        #
        # @api public
        # @since x.y.z
        def +(other)
          other.is_a?(Text) ? Text.new(parts + other.parts) : Text.new(parts + [[nil, other]])
        end

        # The length of the text without any styling.
        #
        # @return [Integer]
        #
        # @api public
        # @since x.y.z
        def length
          parts.sum { |_, text| text.is_a?(Text) ? text.length : text.to_s.length }
        end
        alias_method :size, :length

        # @api public
        # @since x.y.z
        def empty?
          length.zero?
        end

        # Pads the text to the given width, counting only what will be seen.
        #
        # @param width [Integer]
        # @param padding [String]
        #
        # @return [Dry::CLI::Style::Text]
        #
        # @api public
        # @since x.y.z
        def ljust(width, padding = " ")
          self + pad(width, padding)
        end

        # @see #ljust
        #
        # @api public
        # @since x.y.z
        def rjust(width, padding = " ")
          Text.new([[nil, pad(width, padding)]] + parts)
        end

        # Returns true if the `other` is equal to self, either another {Text} consisting of the same
        # style and text parts, or a `String` with the same content.
        #
        # @api private
        def ==(other)
          case other
          when Text then other.parts == parts
          when String then to_s == other
          else false
          end
        end

        # Returns true only if the `other` is another {Text} with the same style and text parts.
        #
        # @api private
        def eql?(other)
          other.is_a?(Text) && other.parts == parts
        end

        # @api private
        def hash
          [self.class, parts].hash
        end

        # @api private
        def inspect
          "#<#{self.class.name}#{style_names} #{plain.inspect}>"
        end

        private

        # Returns the unique set of styles this text renders with, for including in {#inspect}.
        #
        # Returns `"(bold.red, dim)"`, or `""` when it has none.
        def style_names
          names = parts.map(&:first).compact.map(&:to_s).reject(&:empty?).uniq
          return "" if names.empty?

          "(#{names.join(", ")})"
        end

        def plain_text(text)
          text.is_a?(Text) ? text.plain : text.to_s
        end

        def render_part(style, text, color_level)
          rendered = text.is_a?(Text) ? text.render(color_level) : text.to_s
          style.nil? ? rendered : style.render(rendered, color_level)
        end

        def pad(width, padding)
          missing = width - length
          return "" if missing <= 0

          (padding * missing)[0, missing]
        end
      end
    end
  end
end
