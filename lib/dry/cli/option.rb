# frozen_string_literal: true

module Dry
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

      # The accepted values, as strings.
      #
      # Values are given on the command line as strings, so they're normalized rather than compared
      # across types. `options[:values]` keeps whatever was declared.
      #
      # @api private
      attr_reader :values

      # @since 0.1.0
      # @api private
      def initialize(name, options = {})
        @name = name
        @options = options
        @values = options[:values]&.map(&:to_s)
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
        values ? "#{desc}: (#{values.join("/")})" : desc
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

      # @since NEXT
      # @api private
      def cast_callable
        options[:cast]
      end

      # @since 0.1.0
      # @api private
      def boolean?
        type == :boolean
      end

      # @api private
      def flag?
        type == :flag
      end

      # @since 0.3.0
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
      # rubocop:disable Metrics/PerceivedComplexity
      def parser_options
        dasherized_name = Inflector.dasherize(name)
        parser_options = []

        if boolean?
          parser_options << "--[no-]#{dasherized_name}"
        elsif flag?
          parser_options << "--#{dasherized_name}"
        else
          parser_options << "--#{dasherized_name}=#{name}"
          parser_options << "--#{dasherized_name} #{name}"
        end

        if array?
          # Array options can't also give `values` to OptionParser. This would match against the
          # values array and return a single string member, skipping the `Array` conversion itself.
          # {Parser} validates their values instead.
          parser_options << Array
        elsif values
          parser_options << values
        end

        parser_options.unshift(*alias_names) if aliases.any?
        parser_options << desc if desc
        parser_options
      end
      # rubocop:enable Metrics/PerceivedComplexity

      # @since 0.1.0
      # @api private
      def alias_names
        aliases
          .map { |name| name.gsub(/^-{1,2}/, "") }
          .compact
          .uniq
          .map { |name| name.size == 1 ? "-#{name}" : "--#{name}" }
          .map { |name| boolean? || flag? ? name : "#{name} VALUE" }
      end

      # @api private
      def valid_value?(value)
        return true if value.nil? && !required?
        return true if values.nil?

        if array?
          value.all? { accepted_value?(_1) }
        else
          accepted_value?(value)
        end
      end

      def cast(value)
        return value unless cast_callable.respond_to?(:call)

        if array?
          value.map { cast_single(_1) }
        else
          cast_single(value)
        end
      end

      private

      def accepted_value?(value)
        values.include?(value.to_s)
      end

      def cast_single(value)
        cast_callable.call(value)
      rescue StandardError => exception
        raise CastError.new(arg_name: name, original_exception: exception)
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
