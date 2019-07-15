# frozen_string_literal: true

require "hanami/cli/shell_helper"

RSpec.describe Hanami::CLI::ShellHelper do
  let(:stdout) { instance_double(IO) }

  subject do
    Hanami::CLI::ShellHelper.new(out: stdout)
  end

  describe "#execute" do
    it "executes command" do
      expect(Kernel).to receive(:system).with(
        "arbitrary_command",
        Hash[argument: 1]
      )
      expect(stdout).to receive(:puts).with(
        "         run  arbitrary_command\n"
      )
      subject.execute("arbitrary_command", argument: 1)
    end
  end
end
