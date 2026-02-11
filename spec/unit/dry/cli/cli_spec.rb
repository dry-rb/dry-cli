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
      end.then { Dry.CLI(it) }
    end

    it "does not fail when optional argument is missing" do
      result = capture_error { cli.call(arguments: ["one"]) }
      expect(result).not_to match("ERROR")
    end
  end

  context "with command" do
    let(:cli) { Dry.CLI(Baz::CLI) }
    let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

    it "shows help" do
      output = capture_output { cli.call(arguments: ["-h"]) }
      expected_output = <<~OUTPUT
        Command:
          #{cmd}

        Usage:
          #{cmd} MANDATORY_ARG [OPTIONAL_ARG]

        Description:
          Baz command line interface

        Arguments:
          MANDATORY_ARG                     # REQUIRED Mandatory argument
          OPTIONAL_ARG                      # Optional argument (has to have default value in call method)

        Options:
          --option-one=VALUE, -1 VALUE      # Option one
          --[no-]boolean-option, -b         # Option boolean
          --option-with-default=VALUE, -d VALUE  # Option default, default: "test"
          --help, -h                        # Print this help
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

    it "exposes @out and @err to command without overriding pre-existing ivars" do
      # @out and @err are exposed by default
      command_class = Class.new(Dry::CLI::Command) do
        def call(**)
          @out.puts "out"
          @err.puts "err"
        end
      end
      cli = Dry.CLI(command_class.new)

      default_out = StringIO.new
      default_err = StringIO.new
      cli.call(arguments: [], out: default_out, err: default_err)

      expect(default_out.string).to eq("out\n")
      expect(default_err.string).to eq("err\n")

      # @out and @err do not override pre-existing ivars
      custom_command_class = Class.new(command_class) do
        define_method(:initialize) do |out, err|
          super()
          @out = out
          @err = err
        end
      end

      custom_out = StringIO.new
      custom_err = StringIO.new
      cli = Dry.CLI(custom_command_class.new(custom_out, custom_err))

      default_out = StringIO.new
      default_err = StringIO.new
      cli.call(arguments: [], out: default_out, err: default_err)

      expect(custom_out.string).to eq("out\n")
      expect(custom_err.string).to eq("err\n")
      expect(default_out.string).to eq("")
      expect(default_err.string).to eq("")
    end
  end
end
