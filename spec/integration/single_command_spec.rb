# frozen_string_literal: true

require 'open3'

RSpec.describe 'Single command' do
  context 'with command' do
    let(:cmd) { 'baz' }

    it 'shows usage' do
      _, stderr, = Open3.capture3('baz')
      expect(stderr).to eq(
        "ERROR: \"#{cmd}\" was called with no arguments\nUsage: \"#{cmd} MANDATORY_ARG\"\n"
      )
    end

    it 'shows help' do
      output = `baz -h`
      expected_output = <<~OUTPUT
        Command:
          #{cmd}

        Usage:
          #{cmd} MANDATORY_ARG [OPTIONAL_ARG]

        Description:
          Baz command line interface

        Arguments:
          MANDATORY_ARG       	# REQUIRED Mandatory argument
          OPTIONAL_ARG        	# Optional argument (has to have default value in call method)

        Options:
          --option-one=VALUE, -1 VALUE    	# Option one
          --[no-]boolean-option, -b       	# Option boolean
          --option-with-default=VALUE, -d VALUE	# Option default, default: "test"
          --help, -h                      	# Print this help
      OUTPUT
      expect(output).to eq(expected_output)
    end

    it 'with option_one' do
      output = `baz first_arg --option-one=test2`
      expect(output).to eq(
        'mandatory_arg: first_arg. optional_arg: optional_arg. ' \
        "Options: {:option_with_default=>\"test\", :option_one=>\"test2\"}\n"
      )
    end

    it 'with combination of aliases' do
      output = `baz first_arg -bd test3`
      expect(output).to eq(
        'mandatory_arg: first_arg. optional_arg: optional_arg. ' \
        "Options: {:option_with_default=>\"test3\", :boolean_option=>true}\n"
      )
    end
  end
end
