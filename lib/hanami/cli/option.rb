require "hanami/utils/string"

module Hanami
  class Cli
    class Option
      attr_reader :name, :options

      def initialize(name, options = {})
        @name = name
        @options = options
      end

      def alias_name
        options[:alias]
      end

      def desc
        options[:desc]
      end

      def required?
        options[:required]
      end

      def type
        options[:type]
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

      def parser_options
        dasherized_name = Hanami::Utils::String.new(name).dasherize
        parser_options = []
        if type == :boolean
          parser_options << "--[no-]#{dasherized_name}"
        else
          parser_options << "--#{dasherized_name}=#{name}"
          parser_options << "--#{dasherized_name} #{name}"
        end
        parser_options.unshift(alias_name) if alias_name
        parser_options << desc if desc
        parser_options
      end
    end

    class Argument < Option
      def argument?
        true
      end
    end
  end
end
