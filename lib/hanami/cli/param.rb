module Hanami
  module Cli
    class Param
      attr_reader :name, :alias_name, :desc

      def initialize(name, options = {})
        @name = name
        @alias_name = options[:alias]
        @desc = options[:desc]
      end

      def option_parser_options
        [alias_name, "--#{name}=#{name}", "--#{name} #{name}", desc]
      end
    end
  end
end
