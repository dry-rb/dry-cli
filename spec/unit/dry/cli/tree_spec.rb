# frozen_string_literal: true

RSpec.describe Dry::CLI::Tree do
  let(:root) { Foo::CLI::Commands.tree }

  describe "the root" do
    it "has no name or path" do
      expect(root).to have_attributes(name: "", path: [], aliases: [], command: nil)
    end

    it "lists the top-level commands in the order they were registered" do
      expect(root.children.map(&:name).first(4)).to eq(%w[assets console db destroy])
    end
  end

  describe Dry::CLI::Tree::Node do
    subject(:node) { root.dig("db", "migrate") }

    it "describes the command registered at it" do
      expect(node).to have_attributes(
        name: "migrate",
        path: %w[db migrate],
        command: Commands::DB::Migrate,
        description: "Migrate the database",
        hidden?: false,
        callable?: true
      )
      expect(node.examples).to include(["", "Migrate to the last version"])
    end

    it "gives the class of a command registered as an instance" do
      expect(root["with-initializer"].command).to eq(Commands::InitializedCommand)
    end

    it "is not callable for a group registered without a command" do
      expect(root["db"]).to have_attributes(command: nil, callable?: false, description: nil, arguments: [], options: [], examples: [])
    end

    it "is not callable for a namespace" do
      expect(root["namespace"]).to have_attributes(command: Commands::Namespace, callable?: false)
    end

    it "finds a node by alias, under its own name" do
      expect(root.dig("i", "run")&.path).to eq(%w[inherited run])
      expect(root["inherited"].aliases).to eq(["i"])
    end

    it "answers nil for a path that is not registered" do
      expect(root.dig("db", "nope")).to be_nil
      expect(root.dig("nope", "migrate")).to be_nil
    end

    it "compares by the registration it views" do
      expect(root.dig("db", "migrate")).to eq(node)
      expect(root.dig("db", "migrate").hash).to eq(node.hash)
      expect(node.inspect).to eq('#<Dry::CLI::Tree::Node "db migrate">')
    end

    it "serializes itself and everything under it" do
      expect(root["db"].to_h).to include(name: "db", path: ["db"], callable: false)
      expect(root["db"].to_h[:children].map { _1[:name] }).to include("migrate")
    end
  end

  describe Dry::CLI::Tree::Param do
    let(:options) { root["options-with-aliases"].options }

    it "describes an option as it was declared" do
      expect(options.first).to have_attributes(
        name: :url, kind: :option, desc: "The action URL", aliases: %w[-u u --u],
        switches: %w[-u --url], required?: false, option?: true, argument?: false
      )
    end

    it "gives both switches of a boolean" do
      expect(options[1]).to have_attributes(boolean?: true, flag?: false, switches: %w[-f --flag --no-flag])
    end

    it "keeps the declared description apart from its values" do
      option = root["console"].options.first

      expect(option).to have_attributes(desc: "Force a console engine", values: %w[irb pry ripl])
    end

    it "describes an argument" do
      argument = root["root-command"].arguments.first

      expect(argument).to have_attributes(
        name: :root_command_argument, kind: :argument, required?: true, argument?: true, switches: []
      )
    end

    it "describes an array" do
      expect(root["console"].options[1]).to have_attributes(array?: true)
    end

    it "carries declared keys only extensions know about" do
      command = Class.new(Dry::CLI::Command) { argument :path, file: true }

      expect(Dry::CLI::Tree.for(command).arguments.first.metadata).to include(file: true)
    end

    it "is frozen" do
      expect(options.first).to be_frozen
      expect(options.first.metadata).to be_frozen
    end
  end

  describe "#resolve" do
    it "finds the command and the words after it" do
      node, rest = root.resolve(%w[db migrate 42 --force])

      expect(node.path).to eq(%w[db migrate])
      expect(rest).to eq(%w[42 --force])
    end

    it "stops at the deepest node when a word is not registered" do
      node, rest = root.resolve(%w[db nope])

      expect(node.path).to eq(%w[db])
      expect(rest).to eq(%w[nope])
    end

    it "prefers a subcommand of a command that also takes arguments" do
      expect(root.resolve(%w[root-command sub-command]).first.path).to eq(%w[root-command sub-command])
      expect(root.resolve(%w[root-command value]).first.path).to eq(%w[root-command])
    end

    it "follows aliases" do
      expect(root.resolve(%w[i run app]).first.path).to eq(%w[inherited run])
    end

    it "agrees with dispatch" do
      [
        [], %w[nope], %w[db], %w[db migrate], %w[db migrate 1], %w[root-command x],
        %w[root-command sub-command y], %w[i logs app], %w[generate webpack], %w[sub command]
      ].each do |words|
        dispatched = Foo::CLI::Commands.get(words)
        node, rest = root.resolve(words)

        expect([node.command, rest.length]).to eq([dispatched.command.then { _1.is_a?(Class) || _1.nil? ? _1 : _1.class }, words.length - dispatched.names.length]),
          "for #{words.inspect}"
      end
    end
  end

  describe "#walk" do
    let(:registry) do
      Module.new do
        extend Dry::CLI::Registry

        register "visible", Class.new(Dry::CLI::Command)
        register "secret", Class.new(Dry::CLI::Command), hidden: true
        register "secret deeper", Class.new(Dry::CLI::Command)
      end
    end

    it "visits every node, depth first" do
      expect(registry.tree.walk.map(&:path)).to eq([[], ["visible"], ["secret"], %w[secret deeper]])
    end

    it "leaves out hidden nodes and what is under them" do
      expect(registry.tree.walk(hidden: false).map(&:path)).to eq([[], ["visible"]])
      expect(registry.tree.children(hidden: false).map(&:name)).to eq(["visible"])
      expect(registry.tree["secret"]).to be_hidden
    end

    it "yields to a block, and returns the node" do
      seen = []

      expect(registry.tree.walk { seen << _1.name }).to be_a(Dry::CLI::Tree::Node)
      expect(seen).to eq(["", "visible", "secret", "deeper"])
    end

    it "sees commands registered after the tree was taken" do
      tree = registry.tree
      registry.register "late", Class.new(Dry::CLI::Command)

      expect(tree.children.map(&:name)).to include("late")
    end

    it "sees options added after the tree was taken" do
      node = registry.tree["visible"]
      registry.option "visible", :added, type: :flag

      expect(node.options.map(&:name)).to eq([:added])
    end
  end

  describe ".for" do
    subject(:tree) { Dry::CLI::Tree.for(Baz::CLI.new) }

    it "is a root for the command, without children" do
      expect(tree).to have_attributes(path: [], command: Baz::CLI, children: [], callable?: true)
      expect(tree.arguments.map(&:name)).to eq(%i[mandatory_arg optional_arg])
    end
  end

  describe "Dry::CLI#tree" do
    it "is the registry's tree" do
      expect(Dry.CLI(Foo::CLI::Commands).tree.children).to eq(root.children)
    end

    it "is the command's tree for a single command" do
      expect(Dry.CLI(Baz::CLI).tree.command).to eq(Baz::CLI)
    end
  end
end
