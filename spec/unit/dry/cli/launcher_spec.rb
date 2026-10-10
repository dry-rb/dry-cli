# frozen_string_literal: true

require "stringio"

RSpec.describe Dry::CLI::Launcher do
  let(:kernel) { RSpec::Support::FakeKernel.new }

  # A helper built from the command's streams, memoized the documented way: against the stream it
  # was built for, so a reused instance never writes to the streams of an earlier call.
  let(:reporter) do
    Class.new(Dry::CLI::Command) do
      def call(**) = report.puts("reported")

      def report
        @report = nil unless @report_stream.equal?(stdout)
        @report_stream = stdout
        @report ||= Struct.new(:io) { def puts(text) = io.puts(text) }.new(stdout)
      end
    end
  end

  let(:registry) do
    reporter = self.reporter
    Module.new do
      extend Dry::CLI::Registry

      register "hello", (Class.new(Dry::CLI::Command) do
        option :name, default: "world"

        def call(name:, **) = puts("Hello, #{name}!")
      end)
      register "report", reporter
      register "report-instance", reporter.new
      register "fail", (Class.new(Dry::CLI::Command) do
        def call(**) = exit(3)
      end)
    end
  end

  let(:launcher) { described_class[registry] }

  def launch(*argv)
    Struct.new(:stdout, :stderr, :kernel).new(StringIO.new, StringIO.new, RSpec::Support::FakeKernel.new).tap do |run|
      launcher.new(argv, StringIO.new, run.stdout, run.stderr, run.kernel).execute!
    end
  end

  it "runs a command and exits with 0" do
    run = launch("hello")

    expect(run.stdout.string).to eq("Hello, world!\n")
    expect(run.kernel.exits).to eq([0])
  end

  it "keeps the status of a command that exits" do
    expect(launch("fail").kernel.exits).to eq([3])
  end

  it "prints help to its own stdout and exits with 0" do
    run = launch("hello", "--help")

    expect(run.stdout.string).to include("Usage:")
    expect(run.kernel.exits).to eq([0])
  end

  it "prints errors to its own stderr and exits with 1" do
    run = launch("nope")

    expect(run.stderr.string).to include("Commands:")
    expect(run.stdout.string).to be_empty
    expect(run.kernel.exits).to eq([1])
  end

  it "gives each run of a class command its own streams" do
    first = launch("report")
    second = launch("report")

    expect([first.stdout.string, second.stdout.string]).to eq(["reported\n", "reported\n"])
  end

  it "gives each run of an instance command its own streams" do
    first = launch("report-instance")
    second = launch("report-instance")

    expect([first.stdout.string, second.stdout.string]).to eq(["reported\n", "reported\n"])
  end

  it "lets exceptions from a command through" do
    failing = Class.new(Dry::CLI::Command) { def call(**) = raise("boom") }

    expect { described_class[failing].new([], nil, StringIO.new, StringIO.new, kernel).execute! }
      .to raise_error(RuntimeError, "boom")
  end

  it "runs a single command" do
    stdout = StringIO.new
    described_class[Baz::CLI].new(%w[one], nil, stdout, StringIO.new, kernel).execute!

    expect(stdout.string).to include("mandatory_arg: one")
    expect(kernel.exits).to eq([0])
  end

  it "refuses to run when it is not bound to a CLI" do
    expect { described_class.new([]).execute! }.to raise_error(ArgumentError, /no CLI to launch/)
  end

  describe "defaults" do
    let(:pinned) { StringIO.new }

    it "uses what .[] pinned when given only argv" do
      described_class[registry, stdout: pinned, kernel:].new(%w[hello]).execute!

      expect(pinned.string).to eq("Hello, world!\n")
      expect(kernel.exits).to eq([0])
    end

    it "prefers what it is given over what .[] pinned" do
      given = StringIO.new
      described_class[registry, stdout: pinned].new(%w[hello], nil, given, nil, kernel).execute!

      expect(given.string).to eq("Hello, world!\n")
      expect(pinned.string).to be_empty
    end

    it "takes the globals when it is created, not when it is bound" do
      bound = described_class[registry]
      output = StringIO.new
      with_stdout(output) { bound.new(%w[hello], nil, nil, nil, kernel).execute! }

      expect(output.string).to eq("Hello, world!\n")
    end

    it "exits through Kernel by default" do
      expect { described_class[registry].new(%w[hello], nil, StringIO.new).execute! }
        .to raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
    end

    it "exposes what it was given" do
      launched = described_class[registry].new(%w[hello], :in, :out, :err, kernel)

      expect(launched).to have_attributes(argv: %w[hello], stdin: :in, stdout: :out, stderr: :err, kernel:)
    end
  end
end
