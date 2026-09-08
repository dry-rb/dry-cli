# frozen_string_literal: true

module Dry
  class CLI
    # Yield to a block on a regular interval
    #
    # @api private
    # @since x.y.z
    class Ticker
      attr_reader :interval

      # @see #start
      # @api public
      # @since x.y.z
      def self.start(interval: 1.0, &)
        new(interval:).start(&)
      end

      def initialize(interval: 1.0)
        @interval = interval
      end

      # Begin the ticker thread, which will yield to the given block on `interval` seconds.
      #
      # @api public
      # @since x.y.z
      #
      # @yield The block to yield to on each tick
      # @return [self]
      def start
        @running = true
        @thread = Thread.new do
          while @running
            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            yield
            elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
            sleep([@interval - elapsed_time, 0].max)
          end
        end

        self
      end

      # Stop the ticker thread.
      #
      # @api public
      # @since x.y.z
      #
      # @return [void]
      def stop
        @running = false
        @thread&.wakeup if @thread&.alive?
        @thread&.join
      end
    end
  end
end
