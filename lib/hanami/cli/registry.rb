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

      # Register a before callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Proc] the callback
      #
      # @raise [Hanami::CLI::UnkwnownCommandError] if the command isn't registered
      #
      # @since 0.2.0
      #
      # @example
      #   require "hanami/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       class Hello < Hanami::CLI::Command
      #         def call(*)
      #           puts "hello"
      #         end
      #       end
      #
      #       register "hello", Hello
      #       before "hello", -> { puts "I'm about to say.." }
      #     end
      #   end
      def before(command_name, &callback)
        command(command_name).before_callbacks.append(&callback)
      end

      # Register an after callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Proc] the callback
      #
      # @raise [Hanami::CLI::UnkwnownCommandError] if the command isn't registered
      #
      # @since 0.2.0
      #
      # @example
      #   require "hanami/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       class Hello < Hanami::CLI::Command
      #         def call(*)
      #           puts "hello"
      #         end
      #       end
      #
      #       register "hello", Hello
      #       after "hello", -> { puts "world" }
      #     end
      #   end
      def after(command_name, &callback)
        command(command_name).after_callbacks.append(&callback)
      end

      # @since 0.1.0
      # @api private
      def get(arguments)
        @commands.get(arguments)
      end

      private

      COMMAND_NAME_SEPARATOR = " ".freeze

      # @since 0.2.0
      # @api private
      def command(command_name)
        get(command_name.split(COMMAND_NAME_SEPARATOR)).tap do |result|
          raise UnkwnownCommandError.new(command_name) unless result.found?
        end
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
