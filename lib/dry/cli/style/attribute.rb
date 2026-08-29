# frozen_string_literal: true

module Dry
  class CLI
    class Style
      # A non-color style, like bold or underline
      #
      # These look the same on every terminal, so unlike a {Dry::CLI::Style::Color} they ignore
      # the color level.
      #
      # @api private
      class Attribute
        attr_reader :name

        attr_reader :code

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
        def codes(_level)
          [code]
        end

        def ==(other)
          other.is_a?(self.class) && other.code == code
        end
        alias_method :eql?, :==

        def hash
          [self.class, code].hash
        end

        def to_s
          name.to_s
        end
      end
    end
  end
end
