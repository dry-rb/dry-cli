require "hanami/cli/version"

module Hanami
  module Cli
    def self.included(base)
      mod = Module.new do
        def self.call(arguments: ARGV)
          cmd     = arguments.first
          command = constants.find { |c| c.to_s.downcase == cmd }
          exit(1) if command.nil?

          command = const_get(command)

          command.new.call
        end
      end

      base.const_set(:Cli, mod)
    end
  end
end
