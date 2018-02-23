module Hanami
  class CLI
    # @since x.x.x
    class Error < StandardError
    end

    # @since x.x.x
    class UnkwnownCommandError < Error
      # @since x.x.x
      # @api private
      def initialize(command_name)
        super("unknown command: `#{command_name}'")
      end
    end
  end
end
