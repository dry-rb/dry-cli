require "hanami/cli/version"

module Hanami
  module Cli
    def self.included(base)
      mod = Module.new do
        def self.call(arguments: ARGV)
          cmd     = arguments.first
          command = const_get(constants.find { |c| c.to_s.downcase == cmd })

          command.new.call
        end
      end

      base.const_set(:Cli, mod)
    end
  end
end
