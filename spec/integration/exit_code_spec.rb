require_relative 'helpers/constants'
require_relative 'helpers/command_runner'

require 'spec_helper'

RSpec.describe 'Usage and an exit code' do
  let(:command_prefix) { '' }
  let(:argv) { '' }
  let(:command_line) { "#{command_prefix}foo #{argv}" }

  subject(:executioner) { CommandRunner.new(command_line, run_now: true) }

  # This shared example can be customized with an expected output, exit code and an exception
  shared_examples_for :a_command_that_ran_with do |expected_output: FOOS_COMPLETE_OUTPUT, expected_code: 0, expected_error: nil|
    its(:out) { is_expected.to eq(expected_output) }
    its(:code) { is_expected.to eq(expected_code) }
    if expected_error.nil?
      its(:error) { is_expected.to be_nil }
    else
      its(:error) { is_expected.to eq(expected_error) }
    end
  end

  describe 'for a valid command' do
    describe 'with a non-existent subcommand' do
      let(:command_prefix) { 'PRINT_UNKNOWN_COMMANDS=true ' }
      let(:argv) { 'moo' }

      it_behaves_like :a_command_that_ran_with,
                      expected_output: "Error:\n  Unknown command(s): moo\n\n#{FOOS_COMPLETE_OUTPUT}",
                      expected_code: 1
    end

    describe 'with no subcommands but -h or --help options' do
      let(:command_prefix) { 'PRINT_UNKNOWN_COMMANDS=true ' }
      let(:argv) { '-h' }

      it_behaves_like :a_command_that_ran_with
    end

    describe 'with no subcommands nor options' do
      let(:command_prefix) { '' }
      let(:argv) { '' }

      it_behaves_like :a_command_that_ran_with
    end
  end

  describe 'for a totally invalid or non-existent command' do
    let(:command_line) { '/bin/bash -c hello 2>&1' }
    it_behaves_like :a_command_that_ran_with,
                    expected_output: "/bin/bash: hello: command not found\n",
                    expected_code: 127
  end
end
