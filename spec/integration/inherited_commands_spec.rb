# frozen_string_literal: true

require "open3"

RSpec.describe "Inherited commands" do
  context "when --help flag" do
    it "subclass do not" do
      _, stderr, = Open3.capture3("based --help")
      expected = <<~OUT
        Commands:
          based addons APP                # Lists your add-ons and attachments
          based logs APP                  # Display recent log output
          based run APP CMD               # Run a one-off process inside your app
          based subrun APP CMD
      OUT
      expect(stderr).to eq(expected)
    end
  end

  it "works for subclasses" do
    stdout, _, = Open3.capture3("based subrun application_name command_to_run")

    if RUBY_VERSION < "3.4"
      expect(stdout).to eq(
        "Run - App: application_name - Command: command_to_run - Options: {:verbosity=>\"INFO\"}\n"
      )
    else
      expect(stdout).to eq(
        "Run - App: application_name - Command: command_to_run - Options: {verbosity: \"INFO\"}\n"
      )
    end
  end
end
