# frozen_string_literal: true

require "aruba/api"
require "aruba/rspec"

# A launcher for the CLI the other integration specs run as a separate process, run here in the
# same process as the spec.
FooLauncher = Dry::CLI::Launcher[Foo::CLI::Commands]

RSpec.describe "Launcher, in-process with Aruba", type: :aruba do
  before do
    aruba.config.command_launcher = :in_process
    aruba.config.main_class = FooLauncher
  end

  it "captures a command's output and exit status" do
    run_command_and_stop("foo version", fail_on_error: false)

    expect(last_command_started).to have_output("v1.0.0")
    expect(last_command_started).to have_exit_status(0)
  end

  it "captures help" do
    run_command_and_stop("foo version --help", fail_on_error: false)

    expect(last_command_started.stdout).to include("Usage:")
    expect(last_command_started).to have_exit_status(0)
  end

  it "captures an unknown command on stderr, with its exit status" do
    run_command_and_stop("foo nope", fail_on_error: false)

    expect(last_command_started.stderr).to include("Commands:")
    expect(last_command_started).to have_exit_status(1)
  end
end
