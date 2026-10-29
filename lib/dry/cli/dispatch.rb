# frozen_string_literal: true

module Dry
  class CLI
    # Matches the parsed keyword args against the params that a command or callback declares.
    #
    # Commands and callbacks only declare params for the keyword args they care about, but the
    # parsed keyword args also carry whatever other gems have contributed to the same command (see
    # {Registry#option}). This keeps each of them free of a catch-all `**` param just to tolerate
    # keyword args they know nothing about.
    #
    # For public use, see {Dry::CLI.accepted_kwargs}.
    #
    # @api private
    module Dispatch
      # Param kinds that mean the callable can be given every keyword arg. See {.accepted_kwargs}.
      WHOLE_HASH = %i[keyrest req opt rest].freeze

      # The keyword args from `kwargs` that `callable` can accept.
      #
      # Two kinds of callable are given every keyword arg: one declaring a keyword splat param,
      # which absorbs whatever it doesn't name; and one declaring a positional param, because `**`
      # collapses to a single Hash when the callable declares no keyword params.
      #
      # Every other callable is given only the keyword args that match its keyword params. This also
      # means that a callable declaring no params (e.g. `def call`) will receive no args.
      #
      # @param callable [Method, Proc] the command's `#call` method, or a callback
      # @param kwargs [Hash] the parsed keyword args
      #
      # @return [Hash]
      def self.accepted_kwargs(callable, kwargs)
        params = callable.parameters
        return kwargs if params.any? { |type, _| WHOLE_HASH.include?(type) }

        kwargs.slice(*params.filter_map { |type, name| name if type == :key || type == :keyreq })
      end

      # The keyword args that `command` can accept, for commands implementing `#call`.
      #
      # Falls back to all of them for commands that answer `#call` via `method_missing`, and so have
      # no params to inspect.
      #
      # @param command [Dry::CLI::Command] the command instance
      # @param kwargs [Hash] the parsed keyword args
      #
      # @return [Hash]
      def self.command_accepted_kwargs(command, kwargs)
        accepted_kwargs(command.method(:call), kwargs)
      rescue NameError
        kwargs
      end
    end
  end
end
