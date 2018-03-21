module Bar
  module CLI
    module Commands
      extend Hanami::CLI::Registry

      class Alpha < Hanami::CLI::Command
        def call(*)
        end
      end

      register "alpha", Alpha
    end
  end
end
