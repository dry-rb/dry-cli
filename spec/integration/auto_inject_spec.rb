# frozen_string_literal: true

require "stringio"
require "dry/auto_inject"

RSpec.describe "Dependencies injected with dry-auto_inject" do
  let(:container) { {"clock" => -> { "12:00" }, "greeting" => "Hello"} }
  let(:deps) { Dry::AutoInject(container) }

  let(:base) do
    deps = self.deps
    Class.new(Dry::CLI::Command) { include deps["clock", "greeting"] }
  end

  let(:stdout) { StringIO.new }

  def run(command)
    Dry.CLI(command).call(arguments: [], stdout:)
    stdout.string
  end

  it "injects them into a command inheriting from a base command" do
    command = Class.new(base) { def call(**) = puts("#{greeting} at #{clock.call}") }

    expect(run(command)).to eq("Hello at 12:00\n")
  end

  it "injects them alongside the streams, which reach #initialize already set" do
    command = Class.new(base) do
      def initialize(**)
        super
        @seen = stdout.raw
      end

      def call(**) = puts(@seen.equal?(stdout.raw) && greeting)
    end

    expect(run(command)).to eq("Hello\n")
  end

  it "injects them into a command registered as an instance" do
    command = Class.new(base) { def call(**) = puts(greeting) }

    expect(run(command.new)).to eq("Hello\n")
  end

  it "lets an explicit keyword win over the container" do
    command = Class.new(base) { def call(**) = puts(greeting) }

    expect(run(command.new(greeting: "Howdy"))).to eq("Howdy\n")
  end

  it "injects them into a command with its own #initialize that calls super" do
    command = Class.new(base) do
      def initialize(name: "world", **)
        super(**)
        @name = name
      end

      def call(**) = puts("#{greeting}, #{@name}")
    end

    expect(run(command)).to eq("Hello, world\n")
  end

  it "fails for a command with its own #initialize that does not call super" do
    command = Class.new(base) do
      def initialize(name: "world") # rubocop:disable Lint/MissingSuper
        @name = name
      end

      def call(**) = puts(@name)
    end

    expect { run(command) }.to raise_error(ArgumentError, /unknown keyword/)
  end
end
