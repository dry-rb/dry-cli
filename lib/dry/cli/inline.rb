# frozen_string_literal: true

module Dry
  class CLI
    require 'dry/cli'

    module Inline
      extend Forwardable

      AnonymousCommand = Class.new(Dry::CLI::Command)

      delegate %i[desc example argument option] => AnonymousCommand

      def run(arguments: ARGV, out: $stdout)
        command = AnonymousCommand.new
        command.define_singleton_method(:call) do |*args|
          yield(*args)
        end

        Dry.CLI(command).call(arguments: arguments, out: out)
      end
    end
  end
end

include Dry::CLI::Inline
