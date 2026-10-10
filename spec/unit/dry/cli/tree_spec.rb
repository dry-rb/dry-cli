# frozen_string_literal: true

RSpec.describe Dry::CLI::Tree do
  let(:root) { Foo::CLI::Commands.tree }

  describe "the root" do
    subject { root }

    it { is_expected.to have_attributes(name: "", path: [], aliases: [], command: nil) }

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
    end

    it { expect(node.examples).to include(["", "Migrate to the last version"]) }

    describe "for a command registered as an instance" do
      subject { root["with-initializer"] }

      it { is_expected.to have_attributes(command: Commands::InitializedCommand) }
    end

    describe "for a group registered without a command" do
      subject { root["db"] }

      it do
        is_expected.to have_attributes(
          command: nil, callable?: false, description: nil, arguments: [], options: [], examples: []
        )
      end
    end

    describe "for a namespace" do
      subject { root["namespace"] }

      it { is_expected.to have_attributes(command: Commands::Namespace, callable?: false) }
    end

    describe "found by alias" do
      subject { root.dig("i", "run") }

      it { is_expected.to have_attributes(path: %w[inherited run]) }
      it { expect(root["inherited"].aliases).to eq(["i"]) }
    end

    describe "for a path that is not registered" do
      it { expect(root.dig("db", "nope")).to be_nil }
      it { expect(root.dig("nope", "migrate")).to be_nil }
    end

    describe "compared with another view of the same registration" do
      let(:other) { root.dig("db", "migrate") }

      it { is_expected.to eq(other) }
      it { expect(node.hash).to eq(other.hash) }
      it { expect(node.inspect).to eq('#<Dry::CLI::Tree::Node "db migrate">') }
    end

    describe "#to_h" do
      subject(:hash) { root["db"].to_h }

      it { is_expected.to include(name: "db", path: ["db"], callable: false) }
      it { expect(hash[:children].map { |child| child[:name] }).to include("migrate") }
    end
  end

  describe Dry::CLI::Tree::Param do
    subject(:option) { options.first }

    let(:options) { root["options-with-aliases"].options }

    it do
      is_expected.to have_attributes(
        name: :url, kind: :option, desc: "The action URL", aliases: %w[-u u --u],
        switches: %w[-u --url], required?: false, option?: true, argument?: false
      )
    end

    it { is_expected.to be_frozen }
    it { expect(option.metadata).to be_frozen }

    describe "for a boolean" do
      subject { options[1] }

      it { is_expected.to have_attributes(boolean?: true, flag?: false, switches: %w[-f --flag --no-flag]) }
    end

    describe "for an option with values" do
      subject { root["console"].options.first }

      it { is_expected.to have_attributes(desc: "Force a console engine", values: %w[irb pry ripl]) }
    end

    describe "for an array" do
      subject { root["console"].options[1] }

      it { is_expected.to be_array }
    end

    describe "for an argument" do
      subject { root["root-command"].arguments.first }

      it do
        is_expected.to have_attributes(
          name: :root_command_argument, kind: :argument, required?: true, argument?: true, switches: []
        )
      end
    end

    describe "for a key only an extension knows about" do
      subject(:param) { described_class.from(command.arguments.first) }

      let(:command) { Class.new(Dry::CLI::Command) { argument :path, file: true } }

      it { expect(param.metadata).to include(file: true) }
    end

    describe "the values it carries" do
      let(:declared) { root["options-with-aliases"].command.options.first }

      it { expect { option.desc << "!" }.to raise_error(FrozenError) }

      it "leaves the declaration as it was" do
        expect { option.metadata[:aliases] << "-x" }.to raise_error(FrozenError)
        expect(declared.aliases).to eq(%w[-u u --u])
      end
    end
  end

  describe "#resolve" do
    subject(:resolved) { root.resolve(words) }

    let(:node) { resolved.first }
    let(:rest) { resolved.last }

    describe "for a command and the words after it" do
      let(:words) { %w[db migrate 42 --force] }

      it { expect(node.path).to eq(%w[db migrate]) }
      it { expect(rest).to eq(%w[42 --force]) }
    end

    describe "for a word that is not registered" do
      let(:words) { %w[db nope] }

      it { expect(node.path).to eq(%w[db]) }
      it { expect(rest).to eq(%w[nope]) }
    end

    describe "for a subcommand of a command that also takes arguments" do
      let(:words) { %w[root-command sub-command] }

      it { expect(node.path).to eq(%w[root-command sub-command]) }
    end

    describe "for an argument of a command that also has subcommands" do
      let(:words) { %w[root-command value] }

      it { expect(node.path).to eq(%w[root-command]) }
    end

    describe "for an alias" do
      let(:words) { %w[i run app] }

      it { expect(node.path).to eq(%w[inherited run]) }
    end

    [
      [], %w[nope], %w[db], %w[db migrate], %w[db migrate 1], %w[root-command x],
      %w[root-command sub-command y], %w[i logs app], %w[generate webpack], %w[sub command]
    ].each do |command_line|
      describe "for #{command_line.inspect}, compared with dispatch" do
        let(:words) { command_line }
        let(:dispatched) { Foo::CLI::Commands.get(words) }
        let(:dispatched_class) do
          dispatched.command.then { |command| command.is_a?(Class) || command.nil? ? command : command.class }
        end

        it { expect(node.command).to eq(dispatched_class) }
        it { expect(rest.length).to eq(words.length - dispatched.names.length) }
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
    let(:tree) { registry.tree }

    it "visits every node, depth first" do
      expect(tree.walk.map(&:path)).to eq([[], ["visible"], ["secret"], %w[secret deeper]])
    end

    describe "without hidden nodes" do
      it { expect(tree.walk(hidden: false).map(&:path)).to eq([[], ["visible"]]) }
      it { expect(tree.children(hidden: false).map(&:name)).to eq(["visible"]) }
      it { expect(tree["secret"]).to be_hidden }
    end

    describe "with a block" do
      let(:seen) { [] }

      it { expect(tree.walk { |node| seen << node.name }).to be_a(Dry::CLI::Tree::Node) }

      it "yields every node" do
        tree.walk { |node| seen << node.name }
        expect(seen).to eq(["", "visible", "secret", "deeper"])
      end
    end

    describe "after a command is registered" do
      before { tree && registry.register("late", Class.new(Dry::CLI::Command)) }

      it { expect(tree.children.map(&:name)).to include("late") }
    end

    describe "after an option is added" do
      let(:node) { tree["visible"] }

      before { node && registry.option("visible", :added, type: :flag) }

      it { expect(node.options.map(&:name)).to eq([:added]) }
    end
  end

  describe ".for" do
    subject(:tree) { described_class.for(Baz::CLI.new) }

    it { is_expected.to have_attributes(path: [], command: Baz::CLI, children: [], callable?: true) }
    it { expect(tree.arguments.map(&:name)).to eq(%i[mandatory_arg optional_arg]) }
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
