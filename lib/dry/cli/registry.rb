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

      # Returns the class of the command registered under the given name.
      #
      # This is the escape hatch for third-party gems that need to extend a command they don't
      # own: everything {Dry::CLI::Command}'s class-level DSL offers is reachable through it.
      #
      # You should prefer {#option}, which guards against clashing declarations.
      #
      # A command may be registered as an instance rather than a class, in which case this returns
      # its class, since that's what the DSL is on. Either way, any change made through it applies
      # to the command class: it is not scoped to this registration.
      #
      # @param command_name [String] the name used for command registration
      #
      # @return [Class] the registered command's class
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
      #   Foo::Commands.command_class("hello") # => Foo::Commands::Hello
      def command_class(command_name)
        registered = lookup(command_name).command
        registered.is_a?(Class) ? registered : registered.class
      end

      # Add an option to an already registered command.
      #
      # Adding the same option more than once is allowed, so that independent gems can each
      # contribute it without coordinating, as long as they agree on `:type`, `:required`,
      # `:values` and `:default`. Repeat declarations are otherwise ignored, so the first `:desc`
      # wins.
      #
      # Note this extends the command class, so it is not scoped to a single registration, and a
      # subclass defined before the call won't inherit the option.
      #
      # There is no equivalent for arguments. Arguments are matched to the command line by
      # position, so what an externally added one means would depend on the order the contributing
      # gems happen to be loaded.
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
        new_option = Option.new(name, options)

        @_mutex.synchronize do
          klass = command_class(command_name)
          existing = klass.options.find { _1.name == new_option.name }

          if existing
            incompatible = new_option.incompatible_options(existing)
            unless incompatible.empty?
              raise IncompatibleOptionError.new(command_name, new_option.name, incompatible)
            end
          else
            klass.option(new_option.name, new_option.options)
          end

          nil
        end
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

      # @since 0.2.0
      # @api private
      #
      def _callback(callback, blk)
        return blk if blk.respond_to?(:to_proc)

        # Use a given proc directly. Taking `method(:call)` on a proc gives us `Proc#call`, whose
        # parameters are `[[:rest]]` regardless of the proc's own signature, leaving {Dispatch}
        # nothing to match against.
        return callback if callback.is_a?(Proc)

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
