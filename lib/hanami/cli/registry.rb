require "hanami/cli/command_registry"

module Hanami
  class CLI
    # Registry mixin
    #
    # @since 0.1.0
    module Registry
      # @since 0.1.0
      # @api private
      def self.extended(base)
        base.class_eval do
          @commands = CommandRegistry.new
        end
      end

      # Register a command
      #
      # @param name [String] the command name
      # @param command [NilClass,Hanami::CLI::Command] the optional command
      # @param aliases [Array<String>] an optional list of aliases
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Register a command
      #   require "hanami/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       class Hello < Hanami::CLI::Command
      #       end
      #
      #       register "hi", Hello
      #     end
      #   end
      #
      # @example Register a command with aliases
      #   require "hanami/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       class Hello < Hanami::CLI::Command
      #       end
      #
      #       register "hello", Hello, aliases: ["hi", "ciao"]
      #     end
      #   end
      #
      # @example Register a group of commands
      #   require "hanami/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       module Generate
      #         class App < Hanami::CLI::Command
      #         end
      #
      #         class Action < Hanami::CLI::Command
      #         end
      #       end
      #
      #       register "generate", aliases: ["g"] do |prefix|
      #         prefix.register "app",    Generate::App
      #         prefix.register "action", Generate::Action
      #       end
      #     end
      #   end
      def register(name, command = nil, aliases: [], **options)
        if block_given?
          yield Prefix.new(@commands, name, aliases)
        else
          @commands.set(name, command, aliases, **options)
        end
      end

      # @since 0.1.0
      # @api private
      def get(arguments)
        @commands.get(arguments)
      end

      # @since x.x.x
      # @api private
      def before(command, &callback)
        command_class(command).before(&callback)
      end

      # @since x.x.x
      # @api private
      def after(command, &callback)
        command_class(command).after(&callback)
      end

      # @since x.x.x
      # @api private
      def command_class(command)
        get(command.split(' ')).command.class
      end

      # Command name prefix
      #
      # @since 0.1.0
      class Prefix
        # @since 0.1.0
        # @api private
        def initialize(registry, prefix, aliases)
          @registry = registry
          @prefix   = prefix

          registry.set(prefix, nil, aliases)
        end

        # @since 0.1.0
        #
        # @see Hanami::CLI::Registry#register
        def register(name, command, aliases: [], **options)
          command_name = "#{prefix} #{name}"
          registry.set(command_name, command, aliases, **options)
        end

        private

        # @since 0.1.0
        # @api private
        attr_reader :registry

        # @since 0.1.0
        # @api private
        attr_reader :prefix
      end
    end
  end
end
