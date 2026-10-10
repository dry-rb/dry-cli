# frozen_string_literal: true

require "stringio"

RSpec.describe "Help pipeline" do
  let(:kernel) { RSpec::Support::FakeKernel.new }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:config) { Dry::CLI::Config.new }
  let(:screens) { [] }

  # Records every screen the renderer is given, then renders as the default renderer does.
  let(:recording_renderer) do
    screens = self.screens
    ->(screen) { screens << screen and Dry::CLI::HelpRenderer.call(screen) }
  end

  def run(*arguments, cli: Dry.CLI(Foo::CLI::Commands, config:))
    cli.call(arguments:, stdout:, stderr:, kernel:)
  end

  describe "the default renderer" do
    it "renders the listing dry-cli has always printed" do
      run("nope")

      expected = Dry::CLI::Usage.call(Foo::CLI::Commands.get([]))
      expect(stderr.string).to eq("#{expected}\n")
    end

    it "puts the suggestion above the listing" do
      run("consol")

      expect(stderr.string).to start_with("I don't know how to 'consol'. Did you mean: 'console' ?\n\nCommands:\n")
    end

    it "renders a command's banner" do
      run("console", "-h")

      expect(stdout.string).to eq("#{Dry::CLI::Banner.call(Commands::Console, "rspec console")}\n")
    end

    it "lists a level by the names given, aliases included" do
      run("d")

      expect(stderr.string).to include("rspec d action")
    end
  end

  describe "the screen" do
    before { config.help.renderer = recording_renderer }

    it "describes a command's help" do
      run("db", "migrate", "--help")

      expect(screens.last).to have_attributes(
        kind: :command, reason: :help, prog_name: "rspec db migrate", long: true, status: 0,
        arguments: %w[db migrate --help], suggestion: nil, command?: true, listing?: false
      )
      expect(screens.last.node.path).to eq(%w[db migrate])
    end

    it "describes a listing with no command" do
      run("db")

      expect(screens.last).to have_attributes(kind: :listing, reason: :no_command, status: 1, prog_name: "rspec db")
      expect(screens.last.node.path).to eq(%w[db])
    end

    it "describes a listing asked for with a help flag" do
      run("-h")

      expect(screens.last).to have_attributes(kind: :listing, reason: :help, long: false, status: 1)
    end

    it "describes a listing asked for with --help" do
      run("--help")

      expect(screens.last).to have_attributes(reason: :help, long: true)
    end

    it "describes an unknown command, with a suggestion" do
      run("consol")

      expect(screens.last).to have_attributes(reason: :unknown, suggestion: a_string_including("console"))
    end

    it "describes a namespace run without a subcommand, which prints without exiting" do
      run("namespace")

      expect(screens.last).to have_attributes(kind: :listing, reason: :no_command, status: nil)
      expect(stderr.string).to start_with("Commands:")
      expect(kernel.exits).to be_empty
    end

    it "describes a single command's help" do
      run("-h", cli: Dry.CLI(Baz::CLI, config:))

      expect(screens.last).to have_attributes(kind: :command, prog_name: "rspec")
      expect(screens.last.node.command).to eq(Baz::CLI)
    end
  end

  describe "filters" do
    it "run in order, after the renderer" do
      config.help.filters << ->(screen) { screen.with(text: "#{screen.text.lines.first.chomp} [1]") }
      config.help.filters << ->(screen) { screen.with(text: "#{screen.text} [2]") }
      run("console", "-h")

      expect(stdout.string).to eq("Command: [1] [2]\n")
    end

    it "compose with >>" do
      upcase = ->(screen) { screen.with(text: screen.text.upcase) }
      first_line = ->(screen) { screen.with(text: screen.text.lines.first) }
      config.help.filters << (first_line >> upcase)
      run("console", "-h")

      expect(stdout.string).to eq("COMMAND:\n")
    end

    it "can change the status, and so the stream and the exit" do
      config.help.filters << ->(screen) { screen.reason == :help ? screen.with(status: 0) : screen }
      run("-h")

      expect(stdout.string).to start_with("Commands:")
      expect(stderr.string).to be_empty
      expect(kernel.exits).to eq([0])
    end

    it "can leave a screen as it is" do
      config.help.filters << :itself.to_proc
      run("console", "-h")

      expect(stdout.string).to start_with("Command:\n  rspec console")
    end
  end

  describe "a custom renderer" do
    it "replaces the default" do
      config.help.renderer = ->(screen) { screen.with(text: "help for #{screen.node.path.join(" ")}") }
      run("db", "migrate", "-h")

      expect(stdout.string).to eq("help for db migrate\n")
    end
  end

  describe Dry::CLI::Config do
    it "copies its filters with itself" do
      copy = config.dup
      copy.help.filters << :itself.to_proc

      expect(config.help.filters).to be_empty
      expect(copy.help.renderer).to be(Dry::CLI::HelpRenderer)
    end

    it "is read from the process-wide settings when a CLI has none of its own" do
      original = Dry::CLI.config
      Dry::CLI.instance_variable_set(:@config, nil)

      Dry::CLI.configure { |settings| settings.help.renderer = ->(screen) { screen.with(text: "global") } }
      run("console", "-h", cli: Dry.CLI(Foo::CLI::Commands))

      expect(stdout.string).to eq("global\n")
    ensure
      Dry::CLI.instance_variable_set(:@config, original)
    end

    it "keeps a CLI's own settings apart from the process-wide ones" do
      config.help.renderer = ->(screen) { screen.with(text: "own") }
      run("console", "-h")

      expect(stdout.string).to eq("own\n")
      expect(Dry::CLI.config.help.renderer).to be(Dry::CLI::HelpRenderer)
    end
  end

  describe Dry::CLI::Screen do
    subject(:screen) do
      described_class.new(
        kind: :listing, reason: :help, node: Foo::CLI::Commands.tree, prog_name: "foo", long: false,
        arguments: [], suggestion: nil, text: "x", status: 1, stdout: :out, stderr: :err
      )
    end

    it "prints to stderr unless the status is 0" do
      expect(screen.io).to eq(:err)
      expect(screen.with(status: 0).io).to eq(:out)
      expect(screen.with(status: nil).io).to eq(:err)
    end
  end
end
