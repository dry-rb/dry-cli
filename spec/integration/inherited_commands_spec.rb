# frozen_string_literal: true

RSpec.describe 'Inherited commands' do
  context 'when --help flag' do
    it 'subclass do not' do
      output = `based --help 2>&1`
      expected = <<~OUT
        Commands:
          based addons APP                # Lists your add-ons and attachments
          based logs APP                  # Display recent log output
          based run APP CMD               # Run a one-off process inside your app
          based subrun APP CMD
      OUT
      expect(output).to eq(expected)
    end
  end

  it 'works for subclasses' do
    output = `based subrun application_name command_to_run`
    expect(output).to eq(
      "Run - App: application_name - Command: command_to_run - Options: {:verbosity=>\"INFO\"}\n"
    )
  end
end
