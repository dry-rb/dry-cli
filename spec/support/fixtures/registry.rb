# frozen_string_literal: true

module Bar
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Alpha < Dry::CLI::Command
        def call(*)
        end
      end

      register 'alpha', Alpha
    end
  end
end
