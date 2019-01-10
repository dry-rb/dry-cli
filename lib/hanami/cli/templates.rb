module Hanami
  class CLI
    # @since 1.1.0
    # @api private
    class Templates
      # @since 1.1.0
      # @api private
      def initialize(root)
        @root = root
        freeze
      end

      # @since 1.1.0
      # @api private
      def find(*names)
        @root.join(*names)
      end

      private

      # @since 1.1.0
      # @api private
      attr_reader :root
    end
  end
end
