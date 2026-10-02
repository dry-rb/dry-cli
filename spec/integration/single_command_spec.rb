# frozen_string_literal: true

require "open3"

RSpec.describe "Single command" do
  context "with command" do
    let(:cmd) { "baz" }

    it "shows usage" do
      _, stderr, = Open3.capture3("baz")
      expect(stderr).to eq(
        "ERROR: \"#{cmd}\" was called with no arguments\n" \
        "Missing required option: --mandatory-option\n" \
        "Usage: \"#{cmd} MANDATORY_ARG --mandatory-option=VALUE\"\n"
      )
    end

    it "shows help" do
      output = `baz -h`
      expected_output = <<~OUTPUT
        Command:
          baz

        Usage:
          baz MANDATORY_ARG [OPTIONAL_ARG]

        Description:
          Baz command line interface

        Arguments:
          MANDATORY_ARG                          # REQUIRED Mandatory argument
          OPTIONAL_ARG                           # Optional argument (has to have default value in call method)

        Options:
          --option-one=VALUE, -1 VALUE           # Option one
          --[no-]boolean-option, -b              # Option boolean
          --option-with-default=VALUE, -d VALUE  # Option default, default: "test"
          --mandatory-option=VALUE               # REQUIRED Mandatory option
          --mandatory-option-with-default=VALUE  # Mandatory option, default: "mandatory default"
          --help, -h                             # Print this help
      OUTPUT
      expect(output).to eq(expected_output)
    end

    it "with mandatory arg but missing required option" do
      _, stderr, = Open3.capture3("baz first_arg --option_one=test2")

      expect(stderr).to eq(
        "ERROR: \"#{cmd}\" is missing required option --mandatory-option\n" \
        "Usage: \"#{cmd} MANDATORY_ARG --mandatory-option=VALUE\"\n"
      )
    end

    it "with required option but missing mandatory arg" do
      _, stderr, = Open3.capture3("baz --mandatory-option=required")

      expect(stderr).to eq(
        "ERROR: \"#{cmd}\" was called with no arguments\n" \
        "Usage: \"#{cmd} MANDATORY_ARG --mandatory-option=VALUE\"\n"
      )
    end

    it "with option_one" do
      output = `baz first_arg --option-one=test2 --mandatory-option=required`

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: required. " \
          "Options: {:option_with_default=>\"test\", :mandatory_option_with_default=>\"mandatory default\", " \
          ":option_one=>\"test2\", :mandatory_option=>\"required\"}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: required. " \
          "Options: {option_with_default: \"test\", mandatory_option_with_default: \"mandatory default\", " \
          "option_one: \"test2\", mandatory_option: \"required\"}\n"
        )
      end
    end

    it "with combination of aliases" do
      output = `baz first_arg -bd test3 --mandatory-option=required`

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: required. " \
          "Options: {:option_with_default=>\"test3\", :mandatory_option_with_default=>\"mandatory default\", " \
          ":boolean_option=>true, :mandatory_option=>\"required\"}\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          "mandatory_option: required. " \
          "Options: {option_with_default: \"test3\", mandatory_option_with_default: \"mandatory default\", " \
          "boolean_option: true, mandatory_option: \"required\"}\n"
        )
      end
    end
  end

  context "root command with arguments and subcommands" do
    it "with arguments" do
      output = `foo root-command "hello world"`

      expected = <<~DESC
        I'm a root-command argument:hello world
        I'm a root-command option:
      DESC

      expect(output).to eq(expected)
    end

    it "with options" do
      output = `foo root-command "hello world" --root-command-option="bye world"`

      expected = <<~DESC
        I'm a root-command argument:hello world
        I'm a root-command option:bye world
      DESC

      expect(output).to eq(expected)
    end
  end
end
