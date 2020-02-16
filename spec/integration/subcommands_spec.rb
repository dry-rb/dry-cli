# frozen_string_literal: true

require 'open3'

RSpec.describe 'Subcommands' do
  context 'works with params' do
    it 'with help param' do
      output = `foo generate model --help`

      expected = <<~DESC
        Command:
          foo generate model

        Usage:
          foo generate model MODEL

        Description:
          Generate a model

        Arguments:
          MODEL               	# REQUIRED Model name (eg. `user`)

        Options:
          --[no-]skip-migration           	# Skip migration, default: false
          --help, -h                      	# Print this help

        Examples:
          foo generate model user                  # Generate `User` entity, `UserRepository` repository, and the migration
          foo generate model user --skip-migration # Generate `User` entity and `UserRepository` repository
      DESC

      expect(output).to eq(expected)
    end
  end

  context 'works with root subcommands' do
    it 'with root command' do
      output = `foo root --url=google`

      expected = <<~DESC
        I am not a subcommand:
        url:google
      DESC

      expect(output).to eq(expected)
    end

    it 'with root command' do
      output = `foo root foo`

      expected = <<~DESC
        I am not a subcommand:foo
        url:
      DESC

      expect(output).to eq(expected)
    end

    it 'with root leaf' do
      output = `foo root leaf`

      expected = <<~DESC
        I am a subcommand!
      DESC

      expect(output).to eq(expected)
    end

    it 'should display help for root command' do
      output = `foo root --help`

      expected = <<~DESC
        Command:
          foo root

        Usage:
          foo root [NOT_A_SUBCMD]
        
        Description:
          root for a subcommand

        Arguments:
          NOT_A_SUBCMD        	# optional argument

        Options:
          --url=VALUE                     	# Any URL
          --help, -h                      	# Print this help
      DESC

      expect(output).to eq(expected)
    end

    it 'should display help for subcommand' do
      output = `foo root leaf --help`

      expected = <<~DESC
        Command:
          foo root leaf

        Usage:
          foo root leaf

        Description:
          leaf subcommand

        Options:
          --help, -h                      	# Print this help
      DESC

      expect(output).to eq(expected)
    end
  end
end
