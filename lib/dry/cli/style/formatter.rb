# frozen_string_literal: true

module Dry
  class CLI
    class Style
      # Implements `%` formatting logic on behalf of Style::Text objects,
      # while respecting part boundaries.
      #
      # @api private
      module Formatter
        # Formatting re-applies the full argument list while walking each part, so
        # Ruby warns about this file whenever a part consumes fewer arguments than
        # are supplied. Filter out that one warning rather than mutating $VERBOSE,
        # which is global and cannot be made thread-safe. This intentionally
        # bypasses downstream Warning handlers for this message.
        ::Warning.singleton_class.prepend(Module.new do
          def warn(message, category: nil, **)
            if message.include?("dry/cli/style/formatter.rb") &&
              message.include?("warning: too many arguments for format string")

              return
            end

            super
          end
        end)

        class << self
          # Apply formatting to a Style::Text object.
          #
          # Arguments are normalized the way String#% sees them: an object that
          # converts to an array is applied as positional arguments, an object
          # that converts to a hash is applied as named arguments, and anything
          # else is applied as a single value.
          #
          # @param text [Dry::CLI::Style::Text] text that may have formatting directives
          # @param args [Object] formatting parameters
          #
          # @return [Dry::CLI::Style::Text]
          def call(text, args)
            args = Array.try_convert(args) || Hash.try_convert(args) || args
            traverse(text.parts, args).then { Text.new(_1) }
          end

          private

          # Partial application of format arguments is very difficult
          # in the case of sequential, unnamed arguments. The only way
          # to successfully apply formatting to parts is to treat them
          # like slices of a larger string, and apply the formatting
          # incrementally.
          #
          # @param parts [Array<Array(Dry::CLI::Style,String)>]
          # @param args [Object]
          # @param state [Dry::CLI::Style::Formatter::State]
          #
          # @return [Array<Array(Dry::CLI::Style,String)>]
          def traverse(parts, args, state: State.new)
            parts.map do |style, part|
              if part.is_a?(Text)
                [style, traverse(part.parts, args, state:).then { Text.new(_1) }]
              else
                [style, state.apply(part, args)]
              end
            end
          end
        end

        # This state object appends the unformatted parts into itself
        # and uses @cursor to know where the next part begins. This
        # results in an applied format that retains the part boundaries,
        # with the one tradeoff that the format arguments are consumed
        # multiple times.
        #
        # @api private
        class State < String
          NAMED_REFERENCES = /
            (?<!%)   # only match at the start of a percent run
            %        # directive sigil
            (?:%%)*  # step over escaped percent pairs
            [{<]     # opens %{name} or %<name>s
          /x

          def initialize
            super
            @cursor = 0
          end

          # Incremental string format, with an internal cursor.
          #
          # @param text [#to_s] Text part that may contain formatting directives
          # @param args [Object] formatting arguments
          #
          # @return [String] the formatted part
          def apply(text, args)
            self << text.to_s

            formatted = self % jruby_normalize(args)
            part      = formatted[@cursor..]
            @cursor   = formatted.length

            part
          end

          private

          # This exists to normalize a tricky divergence in behavior between MRI and JRuby. Beware!
          #
          # If: 1. the formatting object is a Hash, and 2. there are no named references, we see the
          # following:
          #
          # @example MRI
          #   "%s %s" % {a: 1}
          #   # => ArgumentError: too few arguments
          #
          # @example JRuby
          #   "%s %s" % {a: 1}
          #   # => "{a: 1} {a: 1}"
          #
          # Wrapping the Hash in an Array ensures that JRuby splats the argument correctly.
          def jruby_normalize(obj)
            return obj unless RUBY_ENGINE == "jruby"
            return obj unless obj.is_a?(Hash)

            match?(NAMED_REFERENCES) ? obj : [obj]
          end
        end
        private_constant :State
      end
    end
  end
end
