# frozen_string_literal: true

require "open3"

RSpec.describe "Single command" do
  context "with command" do
    let(:cmd) { "baz" }

    it "shows usage" do
      _, stderr, = Open3.capture3("baz")
      expect(stderr).to eq(
        "ERROR: \"#{cmd}\" was called with no arguments\n"\
        "Usage: \"#{cmd} MANDATORY_ARG --mandatory-option=VALUE --mandatory-option-with-default=VALUE\"\n"\
        "Missing required options:\n    --mandatory-option=VALUE          # REQUIRED Mandatory option\n"
      )
    end

    it "shows help" do
      output = `baz -h`
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

    context "with mandatory arg and non-required option" do
      it "errors out and shows usage" do
        _, stderr, = Open3.capture3("baz first_arg --option_one=test2")
        expect(stderr).to eq(
          "ERROR: \"#{cmd}\" was called with arguments [\"first_arg\"] and options {:option_one=>\"test2\"}\n" \
          "Usage: \"#{cmd} MANDATORY_ARG --mandatory-option=VALUE --mandatory-option-with-default=VALUE\"\n"\
          "Missing required options:\n    --mandatory-option=VALUE          # REQUIRED Mandatory option\n"
        )
      end
    end

    context "with mandatory arg and mandatory_option" do
      it "works" do
        output = `baz first_arg --mandatory-option=test1`
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: test1. " \
          "Options: {:option_with_default=>\"test\", " \
          ":mandatory_option_with_default=>\"mandatory default\", " \
          ":mandatory_option=>\"test1\"}\n"
        )
      end
    end

    context "with mandatory arg, option_one and mandatory_option" do
      it "works" do
        output = `baz first_arg --mandatory-option=test1 --option_one=test2`
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: test1. " \
          "Options: {:option_with_default=>\"test\", " \
          ":mandatory_option_with_default=>\"mandatory default\", " \
          ":mandatory_option=>\"test1\", :option_one=>\"test2\"}\n"
        )
      end
    end

    context "with combination of aliases" do
      it "works" do
        output = `baz first_arg --mandatory-option test1 -bd test3`
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: test1. " \
          "Options: {:option_with_default=>\"test3\", " \
          ":mandatory_option_with_default=>\"mandatory default\", " \
          ":mandatory_option=>\"test1\", :boolean_option=>true}\n"
        )
      end
    end
  end

  context "root command with arguments and subcommands" do
    context "with arguments" do
      it "works" do
        output = `foo root-command "hello world"`

        expected = <<~DESC
          I'm a root-command argument:hello world
          I'm a root-command option:
        DESC

        expect(output).to eq(expected)
      end
    end

    context "with options" do
      it "works" do
        output = `foo root-command "hello world" --root-command-option="bye world"`

        expected = <<~DESC
          I'm a root-command argument:hello world
          I'm a root-command option:bye world
        DESC

        expect(output).to eq(expected)
      end
    end
  end
end
