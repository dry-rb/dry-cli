# frozen_string_literal: true

module Dry
  class CLI
    require 'dry/cli/command'
    require 'dry/cli/parser'
    require 'dry/cli/banner'
    require 'dry/cli/program_name'

    module Inline
      extend Forwardable

      AnonymousCommand = Class.new(Dry::CLI::Command)

      delegate %i[desc example argument option] => AnonymousCommand

      def run(arguments: ARGV, out: $stdout, &block)
        command = AnonymousCommand.new
        result = Parser.call(command, arguments, command_names)

        if result.help?
          Banner.call(command, out)
          exit(0)
        end

        if result.error?
          out.puts(result.error)
          exit(1)
        end

        command.define_singleton_method(:call) do |*args|
          block.call(*args)
        end
        command.call(result.arguments)
      end

      private

      def command_names
        [ProgramName.call]
      end
    end
  end
end

include Dry::CLI::Inline
