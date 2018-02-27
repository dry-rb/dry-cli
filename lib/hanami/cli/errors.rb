module Hanami
  class CLI
    # @since 0.2.0
    class Error < StandardError
    end

    # @since 0.2.0
    class UnkwnownCommandError < Error
      # @since 0.2.0
      # @api private
      def initialize(command_name)
        super("unknown command: `#{command_name}'")
      end
    end
  end
end
