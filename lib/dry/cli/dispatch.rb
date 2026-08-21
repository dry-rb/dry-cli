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
      # Parameter kinds that mean the callable can be given every param. See {.args_for}.
      WHOLE_HASH = %i[keyrest req opt rest].freeze

      # The params from `args` that `callable` can accept.
      #
      # Two kinds of callable are given every param: one declaring a keyword splat, which absorbs
      # whatever it doesn't name; and one declaring a positional, because `**` collapses to a
      # single Hash when the callable declares no keywords.
      #
      # Every other callable is given only the keywords it declares. This also means that a callable
      # declaring no params (e.g. `def call`) will receive none.
      #
      # @param callable [Method, Proc] the command's `#call` method, or a callback
      # @param args [Hash] the parsed params
      #
      # @return [Hash]
      def self.args_for(callable, args)
        parameters = callable.parameters
        return args if parameters.any? { |type, _| WHOLE_HASH.include?(type) }

        args.slice(*parameters.filter_map { |type, name| name if type == :key || type == :keyreq })
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
