require "hanami/utils/string"

module Hanami
  class CLI
    # Command line option
    #
    # @since 0.1.0
    # @api private
    class Option
      # @since 0.1.0
      # @api private
      attr_reader :name

      # @since 0.1.0
      # @api private
      attr_reader :options

      # @since 0.1.0
      # @api private
      def initialize(name, options = {})
        @name = name
        @options = options
      end

      # @since 0.1.0
      # @api private
      def aliases
        options[:aliases] || []
      end

      # @since 0.1.0
      # @api private
      def desc
        desc = options[:desc]
        values ? "#{desc}: (#{values.join('/')})" : desc
      end

      # @since 0.1.0
      # @api private
      def required?
        options[:required]
      end

      # @since 0.1.0
      # @api private
      def type
        options[:type]
      end

      # @since 0.1.0
      # @api private
      def values
        options[:values]
      end

      # @since 0.1.0
      # @api private
      def boolean?
        type == :boolean
      end

      # @since x.x.x
      # @api private
      def array?
        type == :array
      end

      # @since 0.1.0
      # @api private
      def default
        options[:default]
      end

      # @since 0.1.0
      # @api private
      def description_name
        options[:label] || name.upcase
      end

      # @since 0.1.0
      # @api private
      def argument?
        false
      end

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def parser_options
        dasherized_name = Hanami::Utils::String.dasherize(name)
        parser_options  = []

        if boolean?
          parser_options << "--[no-]#{dasherized_name}"
        else
          parser_options << "--#{dasherized_name}=#{name}"
          parser_options << "--#{dasherized_name} #{name}"
        end

        parser_options << Array if array?
        parser_options << values if values
        parser_options.unshift(alias_name) unless alias_name.nil?
        parser_options << desc if desc
        parser_options
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      private

      # @since 0.1.0
      # @api private
      def alias_name
        aliases.join(" ") if aliases.any?
      end
    end

    # Command line argument
    #
    # @since 0.1.0
    # @api private
    class Argument < Option
      # @since 0.1.0
      # @api private
      def argument?
        true
      end
    end
  end
end
