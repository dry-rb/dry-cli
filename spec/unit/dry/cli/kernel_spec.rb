# frozen_string_literal: true

require "stringio"

RSpec.describe "Exiting through a kernel" do
  let(:kernel) { RSpec::Support::FakeKernel.new }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  def run(cli, *arguments)
    cli.call(arguments:, stdout:, stderr:, kernel:)
  end

  context "with a registry" do
    let(:cli) { Dry.CLI(Foo::CLI::Commands) }

    it "exits with 0 after printing a command's help" do
      run(cli, "console", "--help")

      expect(stdout.string).to include("Usage:\n  rspec console")
      expect(kernel.exits).to eq([0])
    end

    it "exits with 1 after printing an error" do
      run(cli, "console", "--engine=nope")

      expect(stderr.string).to include("was called with invalid argument")
      expect(kernel.exits).to eq([1])
    end

    it "exits with 1 after a typo" do
      run(cli, "consol")

      expect(stderr.string).to include("Did you mean: 'console'")
      expect(kernel.exits).to eq([1])
    end

    it "does not exit after a command runs" do
      run(cli, "console")

      expect(stdout.string).to eq("console - engine: \n")
      expect(kernel.exits).to be_empty
    end

    it "stops at the help, even when the kernel returns from exit" do
      expect { run(cli, "console", "-h") }.not_to raise_error
      expect(stdout.string).not_to include("console - engine")
    end
  end

  context "with a single command" do
    let(:cli) { Dry.CLI(Baz::CLI) }

    it "exits with 0 after printing help" do
      run(cli, "-h")

      expect(stdout.string).to include("Usage:")
      expect(kernel.exits).to eq([0])
    end

    it "exits with 1 when a required argument is missing" do
      run(cli)

      expect(stderr.string).to include("was called with no arguments")
      expect(kernel.exits).to eq([1])
    end
  end

  context "when a signal interrupts the CLI" do
    let(:command) do
      Class.new(Dry::CLI::Command) do
        def call(**) = raise(Interrupt)
      end
    end

    it "exits with 128 plus the signal number" do
      run(Dry.CLI(command))

      expect(kernel.exits).to eq([130])
    end
  end

  context "when a command exits" do
    let(:command) do
      Class.new(Dry::CLI::Command) do
        def call(**)
          return exit(3) if stdin.eof?

          puts "not reached"
        end
      end
    end

    it "exits through the CLI's kernel" do
      Dry.CLI(command).call(arguments: [], stdin: StringIO.new, stdout:, stderr:, kernel:)

      expect(kernel.exits).to eq([3])
      expect(stdout.string).to be_empty
    end

    it "exits through the kernel given to an instance command" do
      Dry.CLI(command.new).call(arguments: [], stdin: StringIO.new, stdout:, stderr:, kernel:)

      expect(kernel.exits).to eq([3])
    end

    it "exits through Kernel when given no kernel" do
      expect { command.new(stdin: StringIO.new).send(:call) }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(3)
      }
    end
  end

  describe Dry::CLI::Command do
    subject(:command) { Class.new(described_class).new(kernel:) }

    it "exposes its kernel" do
      expect(command.kernel).to be(kernel)
    end

    it "defaults to Kernel" do
      expect(Class.new(described_class).new.kernel).to be(Kernel)
    end

    it "keeps the kernel out of #initialize" do
      klass = Class.new(described_class) do
        attr_reader :name

        def initialize(name:) = @name = name # rubocop:disable Lint/MissingSuper
      end

      expect(klass.new(name: "x", kernel:)).to have_attributes(name: "x", kernel:)
    end
  end
end
