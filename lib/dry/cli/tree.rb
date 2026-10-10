# frozen_string_literal: true

require "dry/cli/command_registry"
require "dry/cli/inflector"

module Dry
  class CLI
    # A read-only view of a CLI's commands, for gems that describe a CLI rather than run it: help
    # screens, shell completion, documentation generators.
    #
    # The view is live. Each read goes to the registry, so a command registered after the tree was
    # taken is still in it. Reading one path, with {Node#dig} or {Node#resolve}, visits only the
    # nodes along that path.
    #
    # @example Walking every command
    #   MyApp::Commands.tree.walk do |node|
    #     puts [node.path.join(" "), node.description].join(" # ")
    #   end
    #
    # @example Finding the command a command line would run
    #   node, rest = MyApp::Commands.tree.resolve(%w[db migrate --force])
    #   node.path # => ["db", "migrate"]
    #   rest      # => ["--force"]
    #
    # @see Registry#tree
    # @see Dry::CLI#tree
    #
    # @api public
    # @since x.y.z
    module Tree
      # Returns the tree of a single-command CLI: a root node for the command, with no children.
      #
      # @param command [Dry::CLI::Command, Class] the command, as a class or an instance
      #
      # @return [Node]
      #
      # @api public
      # @since x.y.z
      def self.for(command)
        source = CommandRegistry::Node.new
        source.leaf!(command)
        Node.new(source)
      end

      # One option or argument of a command, as it was declared.
      #
      # @!attribute [r] name
      #   @return [Symbol] the name
      # @!attribute [r] kind
      #   @return [Symbol] `:argument` or `:option`
      # @!attribute [r] type
      #   @return [Symbol, nil] the declared `:type`, e.g. `:boolean`, `:flag` or `:array`
      # @!attribute [r] desc
      #   @return [String, nil] the description, as declared
      # @!attribute [r] default
      #   @return [Object, nil] the default value
      # @!attribute [r] values
      #   @return [Array<String>, nil] the accepted values, as strings
      # @!attribute [r] aliases
      #   @return [Array<String>] the aliases, as declared
      # @!attribute [r] switches
      #   @return [Array<String>] every switch that sets an option, e.g. `["-f", "--force"]`, or
      #     `["--force", "--no-force"]` for a boolean; empty for an argument
      # @!attribute [r] metadata
      #   @return [Hash{Symbol => Object}] every key it was declared with, including any that only
      #     an extension understands, e.g. `file: true`
      #
      # @api public
      # @since x.y.z
      Param = Data.define(:name, :kind, :type, :desc, :required, :default, :values, :aliases,
        :switches, :metadata) do
        # @param param [Dry::CLI::Option, Dry::CLI::Argument]
        #
        # @return [Param]
        #
        # @api private
        def self.from(param)
          new(
            name: param.name.to_sym,
            kind: param.argument? ? :argument : :option,
            type: param.type,
            desc: param.options[:desc],
            required: !!param.required?,
            default: param.default,
            values: param.values&.dup&.freeze,
            aliases: param.aliases.dup.freeze,
            switches: (param.argument? ? [] : switches_for(param)).freeze,
            metadata: param.options.dup.freeze
          )
        end

        # @api private
        def self.switches_for(option)
          name = Inflector.dasherize(option.name)
          long = option.boolean? ? ["--#{name}", "--no-#{name}"] : ["--#{name}"]
          short = option.alias_names.map { _1.split(" ").first }

          short + long
        end
        private_class_method :switches_for

        # @return [Boolean]
        def required? = required

        # @return [Boolean]
        def argument? = kind == :argument

        # @return [Boolean]
        def option? = kind == :option

        # @return [Boolean]
        def boolean? = type == :boolean

        # @return [Boolean]
        def flag? = type == :flag

        # @return [Boolean]
        def array? = type == :array
      end

      # A command, a namespace, or a group of commands registered under a common prefix.
      #
      # @api public
      # @since x.y.z
      class Node
        # @return [String] the name it is registered under, or "" for the root
        #
        # @api public
        attr_reader :name

        # @return [Array<String>] the names leading to it from the root; empty for the root
        #
        # @api public
        attr_reader :path

        # @param source [CommandRegistry::Node]
        # @param path [Array<String>]
        #
        # @api private
        def initialize(source, path = [])
          @source = source
          @path = path.dup.freeze
          @name = path.last || ""
        end

        # @return [Array<String>] its aliases
        #
        # @api public
        def aliases
          return [] unless source.parent

          source.parent.aliases.filter_map { |name, node| name if node.equal?(source) }
        end

        # @return [Boolean] whether it was registered with `hidden: true`
        #
        # @api public
        def hidden?
          !!source.hidden
        end

        # The command registered here, if any.
        #
        # @return [Class, nil] the command's class, also when an instance was registered; nil for
        #   a group registered without a command
        #
        # @api public
        def command
          registered = source.command
          registered.is_a?(Class) || registered.nil? ? registered : registered.class
        end

        # @return [Boolean] whether running it runs a command. False for a namespace, and for a
        #   group registered without a command.
        #
        # @api public
        def callable?
          !command.nil? && command.method_defined?(:call)
        end

        # @return [String, nil]
        #
        # @api public
        def description
          command&.description
        end

        # @return [String, nil]
        #
        # @api public
        def long_description
          command&.long_description
        end

        # @return [Array<Array(String, String)>] each example's arguments, and its description
        #
        # @api public
        def examples
          command&.examples || []
        end

        # @return [Array<Param>] its arguments, in the order they were declared
        #
        # @api public
        def arguments
          params(:arguments)
        end

        # @return [Array<Param>] its options, in the order they were declared
        #
        # @api public
        def options
          params(:options)
        end

        # The nodes registered directly under this one, in the order they were registered.
        #
        # @param hidden [Boolean] whether to include hidden nodes
        #
        # @return [Array<Node>]
        #
        # @api public
        def children(hidden: true)
          nodes = source.children.map { |name, child| Node.new(child, path + [name]) }
          hidden ? nodes : nodes.reject(&:hidden?)
        end

        # Returns the node registered directly under this one by the given name or alias.
        #
        # @param name [String] a name or an alias
        #
        # @return [Node, nil] the node, or nil when there is none
        #
        # @example
        #   tree["db"]
        #
        # @api public
        def [](name)
          child(name)
        end

        # Returns the node the given names lead to, following aliases as a command line would.
        #
        # @param names [Array<String>] names or aliases
        #
        # @return [Node, nil] the node, or nil when there is none
        #
        # @example
        #   tree.dig("db", "migrate")
        #
        # @api public
        def dig(*names)
          names.flatten.reduce(self) { |node, name| node&.child(name) }
        end

        # Returns the deepest node the leading words lead to, and the words left over, by the same
        # rules the CLI uses to decide which command to run.
        #
        # @param words [Array<String>] the words of a command line, without the program name
        #
        # @return [Array(Node, Array<String>)] the node, and the words after it
        #
        # @example
        #   node, rest = tree.resolve(%w[db migrate --force])
        #
        # @api public
        def resolve(words)
          names = CommandRegistry.lookup(source, words).names
          [dig(names), words.drop(names.length)]
        end

        # Visits this node and every node under it, depth first, in the order they were registered.
        #
        # @param hidden [Boolean] whether to visit hidden nodes, and the nodes under them
        #
        # @yieldparam node [Node]
        #
        # @return [Enumerator<Node>, self] an enumerator when no block is given
        #
        # @api public
        def walk(hidden: true, &block)
          return enum_for(:walk, hidden:) unless block

          yield self
          children(hidden:).each { |child| child.walk(hidden:, &block) }
          self
        end

        # @return [Hash{Symbol => Object}] this node and every node under it, as plain data
        #
        # @api public
        def to_h
          {
            name:, path:, aliases:, hidden: hidden?, callable: callable?,
            description:, long_description:, examples:,
            arguments: arguments.map(&:to_h), options: options.map(&:to_h),
            children: children.map(&:to_h)
          }
        end

        # @api private
        def ==(other)
          other.is_a?(Node) && other.source.equal?(source)
        end
        alias_method :eql?, :==

        # @api private
        def hash
          source.hash
        end

        # @api private
        def inspect
          "#<#{self.class.name} #{path.join(" ").inspect}>"
        end

        # @return [CommandRegistry::Node] the registration this node views
        #
        # @api private
        attr_reader :source

        protected

        # @api private
        def child(name)
          found = source.lookup(name)
          return unless found

          canonical = source.children.key(found) || name
          Node.new(found, path + [canonical])
        end

        private

        def params(kind)
          registered = command
          return [] unless registered.respond_to?(kind)

          registered.public_send(kind).map { Param.from(_1) }
        end
      end
    end
  end
end
