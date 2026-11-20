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

      # An option with a default always has a value, so the user never needs to give it.
      def required?
        options[:required] && default.nil?
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

      # Returns the name to show the user in error messages, such as `--mode`.
      def display_name
        "--#{Inflector.dasherize(name)}"
      end

      # Returns the kind of input this is, for error messages: "option" or "argument".
      def kind
        argument? ? "argument" : "option"
      end

      # The subset of `#options` that must match for two declarations of the same option to be
      # interchangeable, normalized for comparison.
      #
      # `:cast` is excluded because it's typically a proc or a Dry::Types object, neither of which
      # compares meaningfully. `:desc`, `:label` and `:aliases` are excluded because they don't
      # change how a value is parsed; the first declaration wins.
      def compatibility_options
        # Compare the declared :required rather than `#required?`, which is false whenever there's
        # a default
        {type: type, required: !!options[:required], values: values, default: default}
      end

      # The names of the `#compatibility_options` that stop this and `other` being interchangeable,
      # if any.
      def incompatible_options(other)
        theirs = other.compatibility_options

        compatibility_options.reject { |name, value| theirs[name] == value }.keys
      end

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

        # Don't give `values` to OptionParser. {Parser} checks them instead, so that it can name
        # the accepted values in its error message, as it does for arguments.
        parser_options << Array if array?

        parser_options.unshift(*alias_names) if aliases.any?
        parser_options << desc if desc
        parser_options
      end

      def alias_names
        aliases
          .map { |name| name.gsub(/^-{1,2}/, "") }
          .compact
          .uniq
          .map { |name| name.size == 1 ? "-#{name}" : "--#{name}" }
          .map { |name| boolean? || flag? ? name : "#{name} VALUE" }
      end

      # Returns the given values that are not among the accepted `values`.
      #
      # Returns an empty array when there are no `values` to check against, or when no value was
      # given (a missing required value is reported separately).
      def invalid_values(value)
        return [] if value.nil? || values.nil?

        Array(value).reject { accepted_value?(_1) }
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
        raise CastError.new(value:, argument: self, original_exception: exception)
      end
    end

    # Command line argument
    #
    # @api private
    class Argument < Option
      def initialize(name, options = {})
        super

        # A default would make a required argument optional when it comes last, and would never be
        # used anywhere else, since giving the arguments after it means giving this one too
        if options[:required] && !default.nil?
          raise CommandDefinitionError, "argument `#{name}' can't be both required and have a default"
        end
      end

      def argument?
        true
      end

      # Returns the name to show the user in error messages, such as `DEST`. This matches the name
      # in the usage line.
      def display_name
        description_name.to_s
      end

      # Returns the name to show in a usage line. Optional arguments are in brackets, such as
      # `[STEPS]`.
      def usage_name
        required? ? display_name : "[#{display_name}]"
      end
    end
  end
end
