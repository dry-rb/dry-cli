# frozen_string_literal: true

require "open3"

RSpec.describe "Inline" do
  context "with command" do
    let(:cmd) { "inline" }

    it "shows help" do
      output = `inline -h`
      expected_output = <<~OUTPUT
        Command:
          inline

        Usage:
          inline MANDATORY_ARG [OPTIONAL_ARG]

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

    it "with underscored option_one" do
      output = `inline first_arg -1 test2 -bd test3`

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          'Options: {:option_with_default=>"test3", :option_one=>"test2", :boolean_option=>true}' \
          "\n"
        )
      else
        expect(output).to eq(
          "mandatory_arg: first_arg. optional_arg: optional_arg. " \
          'Options: {option_with_default: "test3", option_one: "test2", boolean_option: true}' \
          "\n"
        )
      end
    end
  end
end
