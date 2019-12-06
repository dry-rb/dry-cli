require "concurrent/hash"
require 'hanami/utils/callbacks'

module Dry
  class CLI
    # Command registry
    #
    # @since 0.1.0
    # @api private
    class CommandRegistry
      # @since 0.1.0
      # @api private
      def initialize
        @root = Node.new
      end

      # @since 0.1.0
      # @api private
      def set(name, command, aliases, **options)
        node = @root
        command = command_for(name, command, **options)
        name.split(/[[:space:]]/).each do |token|
          node = node.put(node, token)
        end

        node.aliases!(aliases)
        node.leaf!(command) unless command.nil?

        nil
      end

      # @since 0.1.0
      # @api private
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def get(arguments)
        node   = @root
        args   = []
        names  = []
        result = LookupResult.new(node, args, names, node.leaf?)

        arguments.each_with_index do |token, i|
          tmp = node.lookup(token)

          if tmp.nil?
            result = LookupResult.new(node, args, names, false)
            break
          elsif tmp.leaf?
            args   = arguments[i + 1..-1]
            names  = arguments[0..i]
            node   = tmp
            result = LookupResult.new(node, args, names, true)
            break
          else
            names  = arguments[0..i]
            node   = tmp
            result = LookupResult.new(node, args, names, node.leaf?)
          end
        end

        result
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      private

      # @since 0.1.0
      # @api private
      def command_for(name, command, **options)
        if command.nil?
          command
        else
          command.new(command_name: name, **options)
        end
      end

      # Node of the registry
      #
      # @since 0.1.0
      # @api private
      class Node
        # @since 0.1.0
        # @api private
        attr_reader :parent

        # @since 0.1.0
        # @api private
        attr_reader :children

        # @since 0.1.0
        # @api private
        attr_reader :aliases

        # @since 0.1.0
        # @api private
        attr_reader :command

        # @since 0.1.0
        # @api private
        attr_reader :before_callbacks

        # @since 0.1.0
        # @api private
        attr_reader :after_callbacks

        # @since 0.1.0
        # @api private
        def initialize(parent = nil)
          @parent   = parent
          @children = Concurrent::Hash.new
          @aliases  = Concurrent::Hash.new
          @command  = nil

          @before_callbacks = Hanami::Utils::Callbacks::Chain.new
          @after_callbacks = Hanami::Utils::Callbacks::Chain.new
        end

        # @since 0.1.0
        # @api private
        def put(parent, key)
          children[key] ||= self.class.new(parent)
        end

        # @since 0.1.0
        # @api private
        def lookup(token)
          children[token] || aliases[token]
        end

        # @since 0.1.0
        # @api private
        def leaf!(command)
          @command = command
        end

        # @since 0.1.0
        # @api private
        def alias!(key, child)
          @aliases[key] = child
        end

        # @since 0.1.0
        # @api private
        def aliases!(aliases)
          aliases.each do |a|
            parent.alias!(a, self)
          end
        end

        # @since 0.1.0
        # @api private
        def leaf?
          !command.nil?
        end
      end

      # Result of a registry lookup
      #
      # @since 0.1.0
      # @api private
      class LookupResult
        # @since 0.1.0
        # @api private
        attr_reader :names

        # @since 0.1.0
        # @api private
        attr_reader :arguments

        # @since 0.1.0
        # @api private
        def initialize(node, arguments, names, found)
          @node      = node
          @arguments = arguments
          @names     = names
          @found     = found
        end

        # @since 0.1.0
        # @api private
        def found?
          @found
        end

        # @since 0.1.0
        # @api private
        def children
          @node.children
        end

        # @since 0.1.0
        # @api private
        def command
          @node.command
        end

        # @since 0.2.0
        # @api private
        def before_callbacks
          @node.before_callbacks
        end

        # @since 0.2.0
        # @api private
        def after_callbacks
          @node.after_callbacks
        end
      end
    end
  end
end
