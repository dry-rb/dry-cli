require "concurrent/hash"

module Hanami
  class Cli
    module CommandRegistry
      include Enumerable

      def commands
        @commands ||= Concurrent::Hash.new
      end

      def aliases
        @aliases ||= Concurrent::Hash.new
      end

      def command_keys
        commands.keys + aliases.keys
      end

      def each(&block)
        commands.each(&block)
      end

      def register(name, command_class, aliases: [], **options)
        commands[name] = command_class.new(name: name, **options)

        aliases.each do |a|
          self.aliases[a] = name
        end

        self
      end

      def resolve(name)
        commands[name] || aliases[name]
      end

      def resolve_from_arguments(arguments)
        command_names = arguments.take_while { |argument| !argument.start_with?('-') }
        command = nil
        command_names.size.times do |i|
          splitted_names = command_names[0, command_names.size - i]
          command = resolve(splitted_names.join(' '))
          if command
            arguments = arguments - splitted_names
            break
          end
        end
        [command, arguments]
      end
    end
  end
end
