module Hanami
  module Cli
    class Param
      attr_reader :name, :alias_name, :desc

      def initialize(name, options = {})
        @name = name
        @alias_name = options[:alias]
        @desc = options[:desc]
      end
    end
  end
end
