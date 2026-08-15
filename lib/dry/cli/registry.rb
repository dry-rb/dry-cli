# frozen_string_literal: true

require "dry/cli/command_registry"
require "dry/cli/option"

module Dry
  class CLI
    # Registry mixin
    #
    # @since 0.1.0
    module Registry
      # @since 0.1.0
      # @api private
      def self.extended(base)
        base.class_eval do
          @_mutex = Mutex.new
          @commands = CommandRegistry.new
        end
      end

      # Register a command
      #
      # @param name [String] the command name
      # @param command [NilClass,Dry::CLI::Command] the optional command
      # @param aliases [Array<String>] an optional list of aliases
      # @param options [Hash] a set of options
      #
      # @since 0.1.0
      #
      # @example Register a command
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #       end
      #
      #       register "hi", Hello
      #     end
      #   end
      #
      # @example Register a command with aliases
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #       end
      #
      #       register "hello", Hello, aliases: ["hi", "ciao"]
      #     end
      #   end
      #
      # @example Register a group of commands
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       module Generate
      #         class App < Dry::CLI::Command
      #         end
      #
      #         class Action < Dry::CLI::Command
      #         end
      #       end
      #
      #       register "generate", aliases: ["g"] do |prefix|
      #         prefix.register "app",    Generate::App
      #         prefix.register "action", Generate::Action
      #       end
      #     end
      #   end
      def register(name, command = nil, aliases: [], hidden: false, &block)
        @commands.set(name, command, aliases, hidden)

        if block_given?
          prefix = Prefix.new(@commands, name, aliases, hidden)
          if block.arity.zero?
            prefix.instance_eval(&block)
          else
            yield(prefix)
          end
        end
      end

      # Register a before callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Class, #call] the callback object. If a class is given,
      #   it MUST respond to `#call`.
      # @param blk [Proc] the callback espressed as a block
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      # @raise [Dry::CLI::InvalidCallbackError] if the given callback doesn't
      #   implement the required interface
      #
      # @since 0.2.0
      #
      # @example
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
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
      #   require "dry/cli"
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
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
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
      #   require "dry/cli"
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
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
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
        @_mutex.synchronize do
          lookup(command_name).before_callbacks.append(&_callback(callback, blk))
        end
      end

      # Register an after callback.
      #
      # @param command_name [String] the name used for command registration
      # @param callback [Class, #call] the callback object. If a class is given,
      #   it MUST respond to `#call`.
      # @param blk [Proc] the callback espressed as a block
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      # @raise [Dry::CLI::InvalidCallbackError] if the given callback doesn't
      #   implement the required interface
      #
      # @since 0.2.0
      #
      # @example
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
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
      #   require "dry/cli"
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
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
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
      #   require "dry/cli"
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
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
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
        @_mutex.synchronize do
          lookup(command_name).after_callbacks.append(&_callback(callback, blk))
        end
      end

      # Returns the command registered under the given name.
      #
      # This is the escape hatch for third-party gems that need to extend a command they don't
      # own: everything {Dry::CLI::Command}'s class-level DSL offers is reachable through it.
      # Prefer {#option} and {#argument}, which guard against clashing declarations.
      #
      # Note this returns whatever was registered, which may be a command instance rather than a
      # class, and that any change made through it applies to the command class itself: it is not
      # scoped to this registration.
      #
      # @param command_name [String] the name used for command registration
      #
      # @return [Dry::CLI::Command] the registered command
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      #
      # @since NEXT
      #
      # @example
      #   require "dry/cli"
      #
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Hello < Dry::CLI::Command
      #       end
      #
      #       register "hello", Hello
      #     end
      #   end
      #
      #   Foo::Commands.command("hello") # => Foo::Commands::Hello
      def command(command_name)
        lookup(command_name).command
      end

      # Add an option to an already registered command.
      #
      # Adding the same option more than once is allowed, so that independent gems can each
      # contribute it without coordinating, as long as they agree on `:type`, `:required`,
      # `:values` and `:default`. Repeat declarations are otherwise ignored, so the first `:desc`
      # wins.
      #
      # @param command_name [String] the name used for command registration
      # @param name [Symbol] the option name
      # @param options [Hash] a set of options, as per `Dry::CLI::Command.option`
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      # @raise [Dry::CLI::IncompatibleOptionError] if the command already declares an option with
      #   the same name, but with incompatible settings
      #
      # @since NEXT
      #
      # @example
      #   require "dry/cli"
      #
      #   # In the gem that owns the command:
      #   module Foo
      #     module Commands
      #       extend Dry::CLI::Registry
      #
      #       class Generate < Dry::CLI::Command
      #         def call(name:)
      #           # ...
      #         end
      #       end
      #
      #       register "generate", Generate
      #     end
      #   end
      #
      #   # In a third-party gem, alongside its own hook:
      #   Foo::Commands.after "generate", Bar::Callbacks::Generate
      #   Foo::Commands.option "generate", :skip_tests, type: :flag, default: false,
      #                                                 desc: "Skip test generation"
      def option(command_name, name, options = {})
        add_param(command_name, Option.new(name, options))
      end

      # Add an argument to an already registered command.
      #
      # Externally added arguments should be optional: arguments are matched to the command line
      # by position, so adding a required one changes the meaning of the arguments that follow it.
      #
      # @param command_name [String] the name used for command registration
      # @param name [Symbol] the argument name
      # @param options [Hash] a set of options, as per `Dry::CLI::Command.argument`
      #
      # @raise [Dry::CLI::UnknownCommandError] if the command isn't registered
      # @raise [Dry::CLI::IncompatibleOptionError] if the command already declares an argument
      #   with the same name, but with incompatible settings
      #
      # @since NEXT
      #
      # @see #option
      def argument(command_name, name, options = {})
        add_param(command_name, Argument.new(name, options))
      end

      # @since 0.1.0
      # @api private
      def get(arguments)
        @commands.get(arguments)
      end

      private

      COMMAND_NAME_SEPARATOR = " "

      # @since 0.2.0
      # @api private
      def lookup(command_name)
        get(command_name.split(COMMAND_NAME_SEPARATOR)).tap do |result|
          raise UnknownCommandError, command_name unless result.found?
        end
      end

      # @since NEXT
      # @api private
      def add_param(command_name, param)
        @_mutex.synchronize do
          klass = command_class(command_name)
          existing = (param.argument? ? klass.arguments : klass.options).find { _1.name == param.name }

          if existing
            differences = param.differences_from(existing)
            unless differences.empty?
              raise IncompatibleOptionError.new(command_name, param.name, differences)
            end
          elsif param.argument?
            klass.argument(param.name, param.options)
          else
            klass.option(param.name, param.options)
          end

          nil
        end
      end

      # The class to extend, for commands registered as an instance.
      #
      # @since NEXT
      # @api private
      def command_class(command_name)
        registered = command(command_name)
        registered.is_a?(Class) ? registered : registered.class
      end

      # @since 0.2.0
      # @api private
      #
      def _callback(callback, blk)
        return blk if blk.respond_to?(:to_proc)

        case callback
        when ->(c) { c.respond_to?(:call) }
          callback.method(:call)
        when Class
          begin
            _callback(callback.new, blk)
          rescue ArgumentError
            raise InvalidCallbackError, callback
          end
        else
          raise InvalidCallbackError, callback
        end
      end

      # Command name prefix
      #
      # @since 0.1.0
      class Prefix
        # @since 0.1.0
        # @api private
        def initialize(registry, prefix, aliases, hidden)
          @registry = registry
          @prefix   = prefix

          registry.set(prefix, nil, aliases, hidden)
        end

        # @since 0.1.0
        #
        # @see Dry::CLI::Registry#register
        def register(name, command = nil, aliases: [], hidden: false, &block)
          command_name = "#{prefix} #{name}"
          registry.set(command_name, command, aliases, hidden)

          if block_given?
            prefix = self.class.new(registry, command_name, aliases, hidden)
            if block.arity.zero?
              prefix.instance_eval(&block)
            else
              yield(prefix)
            end
          end
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
