# frozen_string_literal: true

module RSpec
  module Support
    # Records exits instead of ending the process, like the kernel Aruba runs a CLI in-process with.
    class FakeKernel
      attr_reader :exits

      def initialize
        @exits = []
      end

      def exit(status)
        @exits << status
        nil
      end

      def exitstatus
        case exits.last
        when nil, true then 0
        when false then 1
        else exits.last
        end
      end
    end
  end
end
