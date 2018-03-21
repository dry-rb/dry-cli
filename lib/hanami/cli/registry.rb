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
      # @param callback [Class, #call] the callback object. If a class is given,
      #   it MUST respond to `#call`.
      # @param blk [Proc] the callback espressed as a block
      #
      # @raise [Hanami::CLI::UnkwnownCommandError] if the command isn't registered
      # @raise [Hanami::CLI::InvalidCallbackError] if the given callback doesn't
      #   implement the required interface
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
      #
      # @example Register an object as callback
      #   require "hanami/cli"
      #
      #   module Callbacks
      #     class Hello
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       class Hello < Hanami::CLI::Command
      #         def call(*)
      #           puts "I'm about to say.."
      #         end
      #       end
      #
      #       register "hello", Hello
      #       before "hello", Callbacks::Hello.new
      #     end
      #   end
      #
      # @example Register a class as callback
      #   require "hanami/cli"
      #
      #   module Callbacks
      #     class Hello
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
      #
      #   module Foo
      #     module Commands
      #       extend Hanami::CLI::Registry
      #
      #       class Hello < Hanami::CLI::Command
      #         def call(*)
      #           puts "I'm about to say.."
      #         end
      #       end
      #
      #       register "hello", Hello
      #       before "hello", Callbacks::Hello
      #     end
      #   end
      def before(command_name, callback = nil, &blk)
        command(command_name).before_callbacks.append(&_callback(callback, blk))
      end

      # Register an after callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Class, #call] the callback object. If a class is given,
      #   it MUST respond to `#call`.
      # @param blk [Proc] the callback espressed as a block
      #
      # @raise [Hanami::CLI::UnkwnownCommandError] if the command isn't registered
      # @raise [Hanami::CLI::InvalidCallbackError] if the given callback doesn't
      #   implement the required interface
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
      #
      # @example Register an object as callback
      #   require "hanami/cli"
      #
      #   module Callbacks
      #     class World
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
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
      #       after "hello", Callbacks::World.new
      #     end
      #   end
      #
      # @example Register a class as callback
      #   require "hanami/cli"
      #
      #   module Callbacks
      #     class World
      #       def call(*)
      #         puts "world"
      #       end
      #     end
      #   end
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
      #       after "hello", Callbacks::World
      #     end
      #   end
      def after(command_name, callback = nil, &blk)
        command(command_name).after_callbacks.append(&_callback(callback, blk))
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

      # @since 0.2.0
      # @api private
      #
      # rubocop:disable Metrics/MethodLength
      def _callback(callback, blk)
        return blk if blk.respond_to?(:to_proc)

        case callback
        when ->(c) { c.respond_to?(:call) }
          callback.method(:call)
        when Class
          begin
            _callback(callback.new, blk)
          rescue ArgumentError
            raise InvalidCallbackError.new(callback)
          end
        else
          raise InvalidCallbackError.new(callback)
        end
      end
      # rubocop:enable Metrics/MethodLength

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
