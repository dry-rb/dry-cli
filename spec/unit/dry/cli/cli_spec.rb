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
end
