require "concurrent"

module Hanami
  module Cli
    require "hanami/cli/version"

    def self.included(base)
      mod = Module.new do
        def self.call(arguments: ARGV)
          cmd     = arguments.first
          command = Hanami::Cli.command(cmd)
          exit(1) if command.nil?

          command.new.call
        end

        # This is only for temporary integration with
        # hanami gem
        def self.run(arguments: ARGV)
          cmd     = arguments.first
          command = Hanami::Cli.command(cmd)
          return false if command.nil?

          command.new.call
          true
        end

        def self.register_as(name, command)
          Hanami::Cli.register_as(name, command)
        end
      end

      base.const_set(:Cli, mod)
    end

    @__commands = Concurrent::Hash.new

    def self.register_as(name, command)
      @__commands[name] = command
    end

    def self.command(name)
      @__commands.fetch(name, nil)
    end
  end
end
