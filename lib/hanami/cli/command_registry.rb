require "concurrent/hash"

module Hanami
  class Cli
    class CommandRegistry
      def initialize
        @root = Node.new
      end

      def set(name, command, aliases)
        node = @root
        command = command_for(command)
        name.split(/[[:space:]]/).each do |token|
          node = node.put(node, token)
        end

        node.aliases!(aliases)
        node.leaf!(command) unless command.nil?

        nil
      end

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

      private

      def command_for(command)
        case command
        when NilClass
          command
        when ->(c) { c.respond_to?(:call) }
          command
        else
          command.new
        end
      end

      class Node
        attr_reader :parent, :children, :aliases, :command

        def initialize(parent = nil)
          @parent   = parent
          @children = Concurrent::Hash.new
          @aliases  = Concurrent::Hash.new
          @command  = nil
        end

        def put(parent, key)
          children[key] ||= self.class.new(parent)
        end

        def lookup(token)
          children[token] || aliases[token]
        end

        def leaf!(command)
          @command = command
        end

        def alias!(key, child)
          @aliases[key] = child
        end

        def aliases!(aliases)
          aliases.each do |a|
            parent.alias!(a, self)
          end
        end

        def leaf?
          !command.nil?
        end
      end

      class LookupResult
        attr_reader :names, :arguments

        def initialize(node, arguments, names, found)
          @node      = node
          @arguments = arguments
          @names     = names
          @found     = found
        end

        def found?
          @found
        end

        def children
          @node.children
        end

        def command
          @node.command
        end
      end
    end
  end
end
