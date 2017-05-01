module Hanami
  module Cli
    class Command
      def self.register(*names)
        names.each do |name|
          Hanami::Cli.register(name, self)
        end
      end
    end
  end
end
