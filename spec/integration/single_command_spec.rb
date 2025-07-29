# frozen_string_literal: true

require "open3"

RSpec.describe "Single command" do
  context "with command" do
    let(:cmd) { "baz" }

    it "shows usage" do
      _, stderr, = Open3.capture3("baz")
      expect(stderr).to eq(
        "ERROR: \"#{cmd}\" was called with no arguments\nUsage: \"#{cmd} MANDATORY_ARG\"\n"
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
          --help, -h                             # Print this help
      OUTPUT
      expect(output).to eq(expected_output)
    end

    it "with option_one" do
      output = `baz first_arg --option-one=test2`

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

    it "with combination of aliases" do
      output = `baz first_arg -bd test3`

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
