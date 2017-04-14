require "hanami/cli/version"

module Hanami
  module Cli
    def self.included(base)
      mod = Module.new do
        def self.call
          puts "world"
        end
      end

      base.const_set(:Cli, mod)
    end
  end
end
