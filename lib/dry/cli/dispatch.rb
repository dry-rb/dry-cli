# frozen_string_literal: true

module Dry
  class CLI
    # Matches parsed params against what a command or callback can actually accept.
    #
    # Commands and callbacks only declare the params they care about, but the parsed params also
    # carry whatever other gems have contributed to the same command (see {Registry#option}). This
    # keeps each of them free of a catch-all `**` just to tolerate params they know nothing about.
    #
    # @api private
    module Dispatch
      # The params from `args` that `callable` can accept.
      #
      # Params are passed through untouched unless the callable declares keywords and no keyword
      # splat. That's deliberate: a callable that declares no keywords at all (`def call(*args)`,
      # or a block) receives the params as a single positional Hash, and must keep receiving all
      # of them.
      #
      # @param callable [Method, Proc] the command's `#call` method, or a callback
      # @param args [Hash] the parsed params
      #
      # @return [Hash]
      def self.args_for(callable, args)
        parameters = callable.parameters
        return args if parameters.any? { |type, _| type == :keyrest }

        keywords = parameters.filter_map { |type, name| name if type == :key || type == :keyreq }
        return args if keywords.empty?

        args.slice(*keywords)
      end

      # The params that `command` can accept, for commands implementing `#call`.
      #
      # Falls back to all of them for commands that answer `#call` via `method_missing`, and so
      # have no signature to inspect.
      #
      # @param command [Dry::CLI::Command] the command instance
      # @param args [Hash] the parsed params
      #
      # @return [Hash]
      def self.command_args_for(command, args)
        args_for(command.method(:call), args)
      rescue NameError
        args
      end
    end
  end
end
