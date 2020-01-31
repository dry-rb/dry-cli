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
end
