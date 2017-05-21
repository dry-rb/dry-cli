module Hanami
  module Cli
    class Command
      def self.desc(description)
        Hanami::Cli.add_option(self, {desc: description})
      end

      def self.aliases(*names)
        Hanami::Cli.add_option(self, {aliases: names})
      end

      def self.register(*names)
        names.each do |name|
          Hanami::Cli.register(name, self)
        end
      end
    end
  end
end
