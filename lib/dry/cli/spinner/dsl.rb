# frozen_string_literal: true

module Dry
  class CLI
    # Block argument yielded to `Spinner.run`. Acts as a pass-through for zero-arity blocks, and provides hooks for
    # per-tick updates for one-arity blocks.
    #
    # @api public
    # @since x.y.z
    class Spinner::DSL
      def self.new(&block)
        dsl = super

        if block.arity.zero?
          # simple case: static spinner text
          dsl.run(&block)
        else
          # support per-tick stream output
          dsl.instance_eval(&block)
        end

        dsl
      end

      def initialize
        @events = {}
      end

      # Ensure that unused handlers can be safely called
      #
      # @return [Array<Proc>] The handlers for the spinner
      #
      # @api private
      def handlers
        noop = proc {}

        [
          @events.fetch(:run, noop),
          @events.fetch(:before_tick, noop),
          @events.fetch(:after_tick, noop)
        ]
      end

      # The main worker thread. This is what the Spinner waits for.
      #
      # @yield The block to run in the worker thread
      # @return [void]
      #
      # @api public
      # @since x.y.z
      def run(&block) = @events[:run] = block

      # Executed before each tick of the spinner. The line has been erased, so the current state
      # of the stream will be a blank slate.
      #
      # @yieldparam stream [Dry::CLI::Stream] The stream to write to
      # @yieldparam data [Hash] The data that will be interpolated into the spinner format string
      # @return [void]
      #
      # @api public
      # @since x.y.z
      def before_tick(&block) = @events[:before_tick] = block

      # Executed after each tick of the spinner. The format string has been written to the stream,
      # so anything you write will be appended after it.
      #
      # @yieldparam stream [Dry::CLI::Stream] The stream to write to
      # @return [void]
      #
      # @api public
      # @since x.y.z
      def after_tick(&block) = @events[:after_tick] = block
    end
  end
end
