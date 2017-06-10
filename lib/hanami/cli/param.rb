module Hanami
  module Cli
    class Param
      attr_reader :name, :alias_name, :desc

      def initialize(name, options = {})
        @name = name
        @alias_name = options[:alias]
        @desc = options[:desc]
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
