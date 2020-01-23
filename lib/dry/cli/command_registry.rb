# frozen_string_literal: true

require 'set'
require 'concurrent/hash'

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
      def set(name, command, aliases)
        node = @root
        name.split(/[[:space:]]/).each do |token|
          node = node.put(node, token)
        end

        node.aliases!(aliases)
        node.leaf!(command) if command

        nil
      end

      # @since 0.1.0
      # @api private
      #
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

          @before_callbacks = Chain.new
          @after_callbacks = Chain.new
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

      # Callbacks chain
      #
      # @since 0.4.0
      # @api private
      class Chain
        # @since 0.4.0
        # @api private
        attr_reader :chain

        # @since 0.4.0
        # @api private
        def initialize
          @chain = Set.new
        end

        # @since 0.4.0
        # @api private
        def append(&callback)
          chain.add(callback)
        end

        # @since 0.4.0
        # @api private
        def run(context, *args)
          chain.each do |callback|
            context.instance_exec(*args, &callback)
          end
        end
      end
    end
  end
end
