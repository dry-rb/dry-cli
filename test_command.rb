require 'hanami/cli'

module Foo
  module CLI
    include Hanami::Cli

    class Server < Hanami::Cli::Command
      register 'server'

      param :port
      param :server
      param :host

      def call
        puts "Server: #{options}"
      end
    end
  end
end

# Foo::CLI.call(arguments: ['server', '--port=1234'])
Foo::CLI.call(arguments: ['server', '--port', '1234'])
