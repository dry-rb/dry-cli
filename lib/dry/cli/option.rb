# frozen_string_literal: true

module Dry
  class CLI
    # Command line option
    #
    # @api private
    class Option
      attr_reader :name

      attr_reader :options

      # The accepted values, as strings.
      #
      # Values are given on the command line as strings, so they're normalized rather than compared
      # across types. `options[:values]` keeps whatever was declared.
      attr_reader :values

      def initialize(name, options = {})
        @name = name
        @options = options
        @values = options[:values]&.map(&:to_s)
      end

      def aliases
        options[:aliases] || []
      end

      def desc
        desc = options[:desc]
        values ? "#{desc}: (#{values_description})" : desc
      end

      def required?
        options[:required]
      end

      def type
        options[:type]
      end

      def cast_callable
        options[:cast]
      end

      # Returns a human-readable list of this option's accepted `values`, e.g. "irb, pry, ripl".
      def values_description
        values&.join(", ")
      end

      def boolean?
        type == :boolean
      end

      def flag?
        type == :flag
      end

      def array?
        type == :array
      end

      def default
        options[:default]
      end

      def description_name
        options[:label] || name.upcase
      end

      def argument?
        false
      end

      # The subset of `#options` that must match for two declarations of the same option to be
      # interchangeable, normalized for comparison.
      #
      # `:cast` is excluded because it's typically a proc or a Dry::Types object, neither of which
      # compares meaningfully. `:desc`, `:label` and `:aliases` are excluded because they don't
      # change how a value is parsed; the first declaration wins.
      def compatibility_options
        {type: type, required: !!required?, values: values, default: default}
      end

      # The names of the `#compatibility_options` that stop this and `other` being interchangeable,
      # if any.
      def incompatible_options(other)
        theirs = other.compatibility_options

        compatibility_options.reject { |name, value| theirs[name] == value }.keys
      end

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

      def alias_names
        aliases
          .map { |name| name.gsub(/^-{1,2}/, "") }
          .compact
          .uniq
          .map { |name| name.size == 1 ? "-#{name}" : "--#{name}" }
          .map { |name| boolean? || flag? ? name : "#{name} VALUE" }
      end

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
    # @api private
    class Argument < Option
      def argument?
        true
      end
    end
  end
end
