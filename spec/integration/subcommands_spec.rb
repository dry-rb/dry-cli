# frozen_string_literal: true

require "open3"

RSpec.describe "Subcommands" do
  context "works with params" do
    it "with help param" do
      output = `foo generate model --help`

      expected = <<~DESC
        Command:
          foo generate model

        Usage:
          foo generate model MODEL

        Description:
          Generate a model

        Arguments:
          MODEL                                     # REQUIRED Model name (eg. `user`)

        Options:
          --[no-]skip-migration                     # Skip migration, default: false
          --help, -h                                # Print this help

        Examples:
          foo generate model user                   # Generate `User` entity, `UserRepository` repository, and the migration
          foo generate model user --skip-migration  # Generate `User` entity and `UserRepository` repository
      DESC
      expect(output).to eq(expected)
    end
  end

  context "works with root command subcommands" do
    it "with params" do
      output = `foo root-command sub-command "hello world"`

      expected = <<~DESC
        I'm a root-command sub-command argument:hello world
        I'm a root-command sub-command option:
      DESC

      expect(output).to eq(expected)
    end

    it "with options" do
      option = '--root-command-sub-command-option="bye world"'
      output = `foo root-command sub-command "hello world" #{option}`

      expected = <<~DESC
        I'm a root-command sub-command argument:hello world
        I'm a root-command sub-command option:bye world
      DESC

      expect(output).to eq(expected)
    end
  end

  context "it works with multi nested prefixed commands" do
    it "nests once" do
      output = `foo nested one`

      expected = "I'm a one level nested command\n"

      expect(output).to eq(expected)
    end

    it "nests twice" do
      output = `foo nested one two`

      expected = "I'm a two level nested command\n"

      expect(output).to eq(expected)
    end

    it "nests thrice" do
      output = `foo nested one two three`

      expected = "I'm a three level nested command\n"

      expect(output).to eq(expected)
    end
  end
end
