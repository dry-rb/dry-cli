# frozen_string_literal: true

RSpec.describe "CLI" do
  context "when registry" do
    context "passing module" do
      include_examples "Commands", WithRegistry
      include_examples "Rendering", WithRegistry
      include_examples "Subcommands", WithRegistry
      include_examples "Inherited commands", WithBlock
      include_examples "Third-party gems", WithRegistry
    end

    context "passing block" do
      include_examples "Commands", WithBlock
      include_examples "Rendering", WithBlock
      include_examples "Subcommands", WithBlock
      include_examples "Inherited commands", WithBlock
      include_examples "Third-party gems", WithBlock
    end

    context "passing block with no arguments" do
      include_examples "Commands", WithZeroArityBlock
      include_examples "Rendering", WithZeroArityBlock
      include_examples "Subcommands", WithZeroArityBlock
      include_examples "Inherited commands", WithZeroArityBlock
      include_examples "Third-party gems", WithZeroArityBlock
    end
  end

  context "optional argument with required values" do
    let(:cli) do
      Class.new(Dry::CLI::Command) do
        argument :first, required: true, values: %w[one two]
        argument :second, required: false, values: %w[one two]

        def call(first:, second: nil)
          puts "first: #{first}, second: #{second}"
        end
      end.then { Dry.CLI(_1) }
    end

    it "does not fail when optional argument is missing" do
      result = capture_output { cli.call(arguments: ["one"]) }
      expect(result).to eq("first: one, second: \n")
    end
  end

  context "with command" do
    let(:cli) { Dry.CLI(Baz::CLI) }
    let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

    it "shows help" do
      output = capture_output { cli.call(arguments: ["-h"]) }
      expected_output = <<~OUTPUT
        Command:
          rspec

        Usage:
          rspec MANDATORY_ARG [OPTIONAL_ARG]

        Description:
          Baz command line interface

        Arguments:
          MANDATORY_ARG                          # REQUIRED Mandatory argument
          OPTIONAL_ARG                           # Optional argument (has to have default value in call method)

        Options:
          --option-one=VALUE, -1 VALUE           # Option one
          --[no-]boolean-option, -b              # Option boolean
          --option-with-default=VALUE, -d VALUE  # Option default, default: "test"
          --help, -h                             # Print this help
      OUTPUT
      expect(output).to eq(expected_output)
    end

    it "with required_argument" do
      output = capture_output { cli.call(arguments: ["first_arg"]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test\"}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test\"}\n"
        )
      end
    end

    it "with optional_arg" do
      output = capture_output { cli.call(arguments: %w[first_arg opt_arg]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: opt_arg. " \
          "Options: {:option_with_default=>\"test\", :args=>[\"opt_arg\"]}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: opt_arg. " \
          "Options: {option_with_default: \"test\", args: [\"opt_arg\"]}\n"
        )
      end
    end

    it "with underscored option_one" do
      output = capture_output { cli.call(arguments: %w[first_arg --option_one=test2]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test\", :option_one=>\"test2\"}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test\", option_one: \"test2\"}\n"
        )
      end
    end

    it "with option_one alias" do
      output = capture_output { cli.call(arguments: %w[first_arg -1 test2]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test\", :option_one=>\"test2\"}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test\", option_one: \"test2\"}\n"
        )
      end
    end

    it "with underscored boolean_option" do
      output = capture_output { cli.call(arguments: %w[first_arg --boolean_option]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test\", :boolean_option=>true}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test\", boolean_option: true}\n"
        )
      end
    end

    it "with boolean_option alias" do
      output = capture_output { cli.call(arguments: %w[first_arg -b]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test\", :boolean_option=>true}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test\", boolean_option: true}\n"
        )
      end
    end

    it "with underscoreed option_with_default alias" do
      output = capture_output { cli.call(arguments: %w[first_arg --option_with_default=test3]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test3\"}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test3\"}\n"
        )
      end
    end

    it "with combination of aliases" do
      output = capture_output { cli.call(arguments: %w[first_arg -bd test3]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {:option_with_default=>\"test3\", :boolean_option=>true}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "Options: {option_with_default: \"test3\", boolean_option: true}\n"
        )
      end
    end
  end

  context "IO streams" do
    it "uses custom stdout for help output" do
      registry = Module.new do
        extend Dry::CLI::Registry
        register "foo", Class.new(Dry::CLI::Command) { desc "A foo command"; def call(*); end }
      end
      cli = Dry::CLI.new(registry)

      io = StringIO.new
      expect { cli.call(arguments: ["foo", "--help"], stdout: io) }.to raise_error(SystemExit)
      expect(io.string).to include("A foo command")
    end

    it "uses custom stderr for error output" do
      registry = Module.new do
        extend Dry::CLI::Registry
        register "foo", Class.new(Dry::CLI::Command) { desc "A foo command"; def call(*); end }
      end
      cli = Dry::CLI.new(registry)

      io = StringIO.new
      expect { cli.call(arguments: ["foo", "--unknown"], stderr: io) }.to raise_error(SystemExit)
      expect(io.string).to eq("ERROR: \"rspec foo\" was called with invalid option \"--unknown\"\n")
    end

    it "passes stdin to command and writes to custom stdout" do
      command_class = Class.new(Dry::CLI::Command) do
        def call(**)
          stdout.puts stdin.gets
        end
      end
      cli = Dry.CLI(command_class)

      input = StringIO.new("hello\n")
      output = StringIO.new
      cli.call(arguments: [], stdin: input, stdout: output)
      expect(output.string).to eq("hello\n")
    end
  end

  context "commands registered as instances" do
    let(:command) do
      Class.new(Dry::CLI::Command) do
        def call(**) = puts("wrote it")
      end
    end

    it "writes to the streams the CLI was given" do
      out = StringIO.new
      cli = Dry.CLI { |c| c.register "run", command.new }

      cli.call(arguments: %w[run], stdout: out, stderr: StringIO.new)

      expect(out.string).to eq "wrote it\n"
    end

    it "writes to the CLI's streams, even when built with a stream of its own" do
      cmd_stdout = StringIO.new
      cli_stdout = StringIO.new
      cli = Dry.CLI { |c| c.register "run", command.new(stdout: cmd_stdout) }

      cli.call(arguments: %w[run], stdout: cli_stdout, stderr: StringIO.new)

      expect(cli_stdout.string).to eq "wrote it\n"
      expect(cmd_stdout.string).to be_empty
    end

    it "leaves the registered command as it found it" do
      instance = command.new
      cli_stdout = StringIO.new
      cli = Dry.CLI { |c| c.register "run", instance }

      cli.call(arguments: %w[run], stdout: cli_stdout, stderr: StringIO.new)
      direct_stdout = capture_output { instance.call }

      # Had we set the streams on the registered command itself, this second call would have gone to
      # the CLI's stream too
      expect(direct_stdout).to eq "wrote it\n"
      expect(cli_stdout.string).to eq "wrote it\n"
    end

    it "uses the streams given for each run" do
      cli = Dry.CLI { |c| c.register "run", command.new }
      first_stdout = StringIO.new
      second_stdout = StringIO.new

      cli.call(arguments: %w[run], stdout: first_stdout, stderr: StringIO.new)
      cli.call(arguments: %w[run], stdout: second_stdout, stderr: StringIO.new)

      expect(first_stdout.string).to eq "wrote it\n"
      expect(second_stdout.string).to eq "wrote it\n"
    end
  end

  context "styling" do
    let(:command) do
      Class.new(Dry::CLI::Command) do
        def call(**)
          stdout.puts Dry::CLI::Style.green["done"]
          stderr.puts Dry::CLI::Style.bold.red["Uh oh"]
        end
      end
    end

    let(:terminal) { StringIO.new.tap { |io| def io.tty? = true } }
    let(:file) { StringIO.new }

    # Pin color_level so we can rely on which escape sequences to test for below.
    around do |example|
      Dry::CLI::Style.color_level = :ansi16
      example.run
      Dry::CLI::Style.color_level = nil
    end

    it "styles a terminal and leaves the stream redirected alongside it plain" do
      Dry.CLI(command).call(arguments: [], stdout: terminal, stderr: file)

      expect(terminal.string).to eq "\e[32mdone\e[0m\n"
      expect(file.string).to eq "Uh oh\n"
    end

    it "keeps color on the terminal when it is the other stream redirected" do
      Dry.CLI(command).call(arguments: [], stdout: file, stderr: terminal)

      expect(file.string).to eq "done\n"
      expect(terminal.string).to eq "\e[1;31mUh oh\e[0m\n"
    end

    it "styles nothing when neither stream is a terminal" do
      err = StringIO.new

      Dry.CLI(command).call(arguments: [], stdout: file, stderr: err)

      expect(file.string).to eq "done\n"
      expect(err.string).to eq "Uh oh\n"
    end
  end
end
