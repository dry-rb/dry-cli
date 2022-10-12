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
          --mandatory-option=VALUE          # REQUIRED Mandatory option
          --mandatory-option-with-default=VALUE  # REQUIRED Mandatory option, default: "mandatory default"
          --help, -h                        # Print this help
      OUTPUT
      expect(output).to eq(expected_output)
    end

    it "with mandatory_arg and mandatory_option" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory-option=mandatory_opt_val]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\"}\n"
      )
    end

    it "with optional_arg" do
      output = capture_output { cli.call(arguments: %w[first_arg opt_arg --mandatory_option=mandatory_opt_val]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: opt_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\", :args=>\[\"opt_arg\"]}\n"
      )
    end

    it "with underscored option_one" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory_option=mandatory_opt_val --option_one=test2]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\", :option_one=>\"test2\"}\n"
      )
    end

    it "with option_one alias" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory-option=mandatory_opt_val -1 test2]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\", :option_one=>\"test2\"}\n"
      )
    end

    it "with underscored boolean_option" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory_option=mandatory_opt_val --boolean_option]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\", :boolean_option=>true}\n"
      )
    end

    it "with boolean_option alias" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory_option=mandatory_opt_val -b]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\", :boolean_option=>true}\n"
      )
    end

    it "with underscored option_with_default alias" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory_option=mandatory_opt_val --option_with_default=test3]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test3\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\"}\n"
      )
    end

    it "with combination of aliases" do
      output = capture_output { cli.call(arguments: %w[first_arg --mandatory_option=mandatory_opt_val -bd test3]) }
      expect(output).to eq(
        "mandatory_arg: first_arg. optional_arg: optional_arg. " \
        "mandatory_option: mandatory_opt_val. " \
        "Options: {:option_with_default=>\"test3\", :mandatory_option_with_default=>\"mandatory default\", " \
        ":mandatory_option=>\"mandatory_opt_val\", :boolean_option=>true}\n"
      )
    end
  end
end
