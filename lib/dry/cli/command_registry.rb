# frozen_string_literal: true

require "dry/cli/dispatch"

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
        @_mutex = Mutex.new
        @root = Node.new
      end

      # @return [Node] the node every registered name starts from
      #
      # @api private
      attr_reader :root

      # @since 0.1.0
      # @api private
      def set(name, command, aliases, hidden)
        @_mutex.synchronize do
          node = @root
          name.split(/[[:space:]]/).each do |token|
            node = node.put(node, token)
          end

          node.aliases!(aliases)
          node.hidden!(hidden)
          if command
            node.leaf!(command)
            node.subcommands!(command)
          end

          nil
        end
      end

      # @since 0.1.0
      # @api private
      def get(arguments)
        @_mutex.synchronize do
          self.class.lookup(@root, arguments)
        end
      end

      # Finds the deepest node the leading arguments lead to, starting from the given node.
      #
      # This is how the CLI decides which command to run, shared with {Dry::CLI::Tree::Node#resolve}
      # so the two can't disagree.
      #
      # @param node [Node] the node to start from
      # @param words [Array<String>] the command line arguments
      #
      # @return [LookupResult]
      #
      # @api private
      def self.lookup(node, words)
        arguments = []
        names = []
        valid_leaf = nil
        result = LookupResult.new(node, arguments, names, node.leaf?)

        words.each_with_index do |word, index|
          child = node.lookup(word)

          if child.nil?
            result = valid_leaf || LookupResult.new(node, arguments, names, false)
            break
          end

          node = child
          names = words[0..index]

          if child.leaf?
            arguments = words[index + 1..]
            result = valid_leaf = LookupResult.new(node, arguments, names, true)
            break unless child.children?
          else
            result = LookupResult.new(node, arguments, names, false)
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

        # @since 1.1.1
        # @api private
        attr_reader :hidden

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
          @children = {}
          @aliases  = {}
          @hidden   = hidden
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

        # @since 0.7.0
        # @api private
        def subcommands!(command)
          command_class = command.is_a?(Class) ? command : command.class
          command_class.subcommands = children
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

        # @since 1.1.1
        # @api private
        def hidden!(hidden)
          @hidden = hidden
        end

        # @since 0.1.0
        # @api private
        def leaf?
          !command.nil?
        end

        # @since 0.7.0
        # @api private
        def children?
          children.any?
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
        def run(context, **args)
          chain.each do |callback|
            context.instance_exec(**Dispatch.args_for(callback, args), &callback)
          end
        end
      end
    end
  end
end
