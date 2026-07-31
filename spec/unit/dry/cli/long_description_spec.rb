# frozen_string_literal: true

RSpec.describe "Long description" do
  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  let(:echo) do
    Class.new(Dry::CLI::Command) do
      desc "Prints given input"
      long_desc <<~DESC
        Prints the given input back to standard output.

        When no input is given, it prints an empty line.
      DESC

      def call(*); end
    end
  end

  let(:short_only) do
    Class.new(Dry::CLI::Command) do
      desc "Only has a short description"

      def call(*); end
    end
  end

  let(:cli) do
    commands = {echo: echo, short_only: short_only}

    Dry.CLI do |c|
      c.register "echo", commands[:echo]
      c.register "short", commands[:short_only]
    end
  end

  it "prints the long description when calling --help" do
    output = capture_output { cli.call(arguments: %w[echo --help]) }

    expected = <<~OUTPUT
      Command:
        #{cmd} echo

      Usage:
        #{cmd} echo

      Description:
        Prints the given input back to standard output.

        When no input is given, it prints an empty line.

      Options:
        --help, -h  # Print this help
    OUTPUT
    expect(output).to eq(expected)
  end

  it "prints the short description when calling -h" do
    output = capture_output { cli.call(arguments: %w[echo -h]) }

    expected = <<~OUTPUT
      Command:
        #{cmd} echo

      Usage:
        #{cmd} echo

      Description:
        Prints given input

      Options:
        --help, -h  # Print this help
    OUTPUT
    expect(output).to eq(expected)
  end

  it "falls back to the short description on --help when no long description is set" do
    output = capture_output { cli.call(arguments: %w[short --help]) }

    expected = <<~OUTPUT
      Command:
        #{cmd} short

      Usage:
        #{cmd} short

      Description:
        Only has a short description

      Options:
        --help, -h  # Print this help
    OUTPUT
    expect(output).to eq(expected)
  end

  context "with a namespace" do
    let(:namespace) do
      Class.new(Dry::CLI::Namespace) do
        desc "Collection of useful commands"
        long_desc <<~DESC
          A longer explanation of what the commands in this
          namespace do and how they relate to each other.
        DESC
      end
    end

    let(:sub) do
      Class.new(Dry::CLI::Command) do
        desc "Do the sub thing"

        def call(*); end
      end
    end

    let(:cli) do
      commands = {namespace: namespace, sub: sub}

      Dry.CLI do |c|
        c.register "ns", commands[:namespace] do |prefix|
          prefix.register "sub", commands[:sub]
        end
      end
    end

    it "prints the long description when calling --help" do
      output = capture_output { cli.call(arguments: %w[ns --help]) }

      expect(output).to include(<<~OUTPUT)
        Description:
          A longer explanation of what the commands in this
          namespace do and how they relate to each other.
      OUTPUT
    end

    it "prints the short description when calling -h" do
      output = capture_output { cli.call(arguments: %w[ns -h]) }

      expect(output).to include("Description:\n  Collection of useful commands")
      expect(output).not_to include("A longer explanation")
    end
  end
end
