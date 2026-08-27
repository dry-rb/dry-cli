# frozen_string_literal: true

module Dry
  class CLI
    class Style
      # A non-color style, like bold or underline
      #
      # These look the same on every terminal, so unlike a {Dry::CLI::Style::Color} they ignore
      # the color level.
      #
      # @since 1.5.0
      # @api private
      class Attribute
        # @since 1.5.0
        # @api private
        attr_reader :name

        # @since 1.5.0
        # @api private
        attr_reader :code

        # @since 1.5.0
        # @api private
        def initialize(name, code)
          @name = name
          @code = code
          freeze
        end

        # Returns the ANSI codes for this attribute
        #
        # @param _level [Symbol] ignored; attributes don't degrade
        #
        # @return [Array<Integer>]
        #
        # @since 1.5.0
        # @api private
        def codes(_level)
          [code]
        end

        # @since 1.5.0
        # @api private
        def ==(other)
          other.is_a?(self.class) && other.code == code
        end
        alias_method :eql?, :==

        # @since 1.5.0
        # @api private
        def hash
          [self.class, code].hash
        end

        # @since 1.5.0
        # @api private
        def to_s
          name.to_s
        end
      end
    end
  end
end
