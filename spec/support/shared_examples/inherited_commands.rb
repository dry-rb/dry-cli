# frozen_string_literal: true

RSpec.shared_examples "Inherited commands" do |cli|
  let(:cli) { cli }

  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  context "with help flag" do
    it "shows subcommands " do
      error = capture_error { cli.call(arguments: %w[i]) }
      expected = <<~DESC
        Commands:
          rspec i addons APP                 # Lists your add-ons and attachments
          rspec i logs APP                   # Display recent log output
          rspec i run APP CMD                # Run a one-off process inside your app
          rspec i subrun APP CMD
      DESC
      expect(error).to eq(expected)
    end

    it "shows run's help" do
      output = capture_output { cli.call(arguments: %w[i run --help]) }
      expected = <<~DESC
        Command:
          #{cmd} i run

        Usage:
          #{cmd} i run APP CMD

        Description:
          Run a one-off process inside your app

        Arguments:
          APP                               # REQUIRED Application name
          CMD                               # REQUIRED Command to execute

        Options:
          --verbosity=VALUE                 # Verbosity level, default: "INFO"
          --help, -h                        # Print this help
      DESC
      expect(output).to eq(expected)
    end

    it "shows subrun's help" do
      output = capture_output { cli.call(arguments: %w[i subrun --help]) }
      expected = <<~DESC
        Command:
          #{cmd} i subrun

        Usage:
          #{cmd} i subrun APP CMD

        Arguments:
          APP                               # REQUIRED Application name
          CMD                               # REQUIRED Command to execute

        Options:
          --verbosity=VALUE                 # Verbosity level, default: "INFO"
          --help, -h                        # Print this help
      DESC
      expect(output).to eq(expected)
    end

    it "shows addon's help" do
      output = capture_output { cli.call(arguments: %w[i addons --help]) }
      expected = <<~DESC
        Command:
          #{cmd} i addons

        Usage:
          #{cmd} i addons APP

        Description:
          Lists your add-ons and attachments

        Arguments:
          APP                               # REQUIRED Application name

        Options:
          --verbosity=VALUE                 # Verbosity level, default: "INFO"
          --[no-]json                       # return add-ons in json format, default: false
          --help, -h                        # Print this help

        Examples:
          #{cmd} i addons APP_NAME
          #{cmd} i addons APP_NAME --json
      DESC
      expect(output).to eq(expected)
    end

    it "shows log's help" do
      output = capture_output { cli.call(arguments: %w[i logs --help]) }
      expected = <<~DESC
        Command:
          #{cmd} i logs

        Usage:
          #{cmd} i logs APP

        Description:
          Display recent log output

        Arguments:
          APP                               # REQUIRED Application name

        Options:
          --verbosity=VALUE                 # Verbosity level, default: "INFO"
          --num=VALUE                       # number of lines to display
          --[no-]tail                       # continually stream log
          --help, -h                        # Print this help

        Examples:
          #{cmd} i logs APP_NAME
          #{cmd} i logs APP_NAME --num=50
          #{cmd} i logs APP_NAME --tail
      DESC
      expect(output).to eq(expected)
    end

    it "shows free form help text" do
      output = capture_output { cli.call(arguments: %w[i logs --help]) }
      expected = <<~DESC
        Command:
          #{cmd} i convert

        Usage:
          #{cmd} i convert

        Description:
          Display recent log output

        Arguments:
          APP                               # REQUIRED Application name

        Options:
          --verbosity=VALUE                 # Verbosity level, default: "INFO"
          --num=VALUE                       # number of lines to display
          --[no-]tail                       # continually stream log
          --help, -h                        # Print this help

        Available timezones:
          AEDT
          CEST
      DESC
      expect(output).to eq(expected)
    end
  end

  context "with inherited arguments" do
    it "run expects APP_NAME and CMD_NAME" do
      output = capture_output { cli.call(arguments: %w[i run application_name command_name]) }
      expect(output).to include("App: application_name - Command: command_name")
    end

    it "subrun expects APP_NAME and CMD_NAME" do
      output = capture_output { cli.call(arguments: %w[i subrun application_name command_name]) }
      expect(output).to include("App: application_name - Command: command_name")
    end

    it "addons expects APP_NAME" do
      output = capture_output { cli.call(arguments: %w[i addons application_name]) }
      expect(output).to include("App: application_name")
    end

    it "logs expects APP_NAME" do
      output = capture_output { cli.call(arguments: %w[i logs application_name]) }
      expect(output).to include("App: application_name")
    end
  end

  context "with inherited options" do
    it "run has default verbosity_level" do
      output = capture_output { cli.call(arguments: %w[i run application_name command_name]) }
      expect(output).to include('Options: {:verbosity=>"INFO"}')
    end

    it "subrun has default verbosity_level too" do
      output = capture_output { cli.call(arguments: %w[i subrun application_name command_name]) }
      expect(output).to include('Options: {:verbosity=>"INFO"}')
    end

    it "addons has verbosity_level set to debug" do
      output = capture_output do
        cli.call(arguments: %w[i addons application_name --verbosity=DEBUG])
      end
      expect(output).to include("Options: {:verbosity=>\"DEBUG\", :json=>false}")
    end

    it "logs has verbosity_level set to WARNING" do
      output = capture_output do
        cli.call(arguments: %w[i logs application_name --verbosity=WARNING])
      end
      expect(output).to include("Options: {:verbosity=>\"WARNING\"}")
    end
  end

  context "with description" do
    it "subclass does not inherit it" do
      output = capture_output { cli.call(arguments: %w[i run --help]) }
      expect(output).not_to include("Base description")
    end

    it "subclasses subclass does not inherit it" do
      output = capture_output { cli.call(arguments: %w[i subrun --help]) }
      expect(output).not_to include("Run a one-off process inside your app")
    end
  end

  context "with example" do
    it "subclass does not inherit it" do
      output = capture_output { cli.call(arguments: %w[i logs --help]) }
      expect(output).not_to include("Base example")
    end
  end

  context "with multible subclasses of Dry::CLI::Command" do
    it "subclasses do nod share options" do
      output = capture_output { cli.call(arguments: %w[i logs application_name --tail --num=50]) }
      expect(output).not_to include(":json=>false}")

      output = capture_output { cli.call(arguments: %w[i addons application_name]) }
      expect(output).not_to include(":tail=>false}")
    end
  end
end
