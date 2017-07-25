require "hanami/cli/command_registry"

module Hanami
  class Cli
    module Registry
      def self.extended(base)
        base.class_eval do
          @commands = CommandRegistry.new
        end
      end

      def register(name, command = nil, aliases: [], **options)
        if block_given?
          yield Prefix.new(@commands, name, aliases)
        else
          @commands.set(name, command, aliases, **options)
        end
      end

      def get(arguments)
        @commands.get(arguments)
      end

      class Prefix
        def initialize(registry, prefix, aliases)
          @registry = registry
          @prefix   = prefix

          registry.set(prefix, nil, aliases)
        end

        def register(name, command, aliases: [], **options)
          command_name = "#{prefix} #{name}"
          registry.set(command_name, command, aliases, **options)
        end

        private

        attr_reader :registry, :prefix
      end
    end
  end
end
