module Hanami
  module Cli
    class Param
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

      def description_name
        options[:label] || name.upcase
      end

      def parser_options
        ["--#{name}=#{name}", "--#{name} #{name}"].tap do |options|
          options.unshift(alias_name) if alias_name
          options << desc if desc
        end
      end
    end
  end
end
