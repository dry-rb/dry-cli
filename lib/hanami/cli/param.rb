module Hanami
  module Cli
    class Param
      attr_reader :name, :alias_name

      def initialize(name:, alias_name:)
        @name = name
        @alias_name = alias_name
      end
    end
  end
end
