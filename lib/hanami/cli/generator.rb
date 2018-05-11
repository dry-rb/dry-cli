require 'hanami/utils/files'
require 'erb'

module Hanami
  class CLI
    # A class to help generate files
    #
    # @since 0.1.0
    class Generator
      # @since x.x.x
      # @api public
      def initialize(out: $stdout, files: Utils::Files)
        @files     = files
        @out       = out
      end

      # @since x.x.x
      # @api public
      def create(source, destination, context)
        files.write(destination, render(source, context))
        say(:create, destination)
      end

      # Should we replace this method with `create` and passing in
      # `source` as `nil`? (and `context` too)
      # @since x.x.x
      # @api public
      def touch(destination)
        files.touch(destination)
        say(:create, destination)
      end

      private

      # @since x.x.x
      # @api private
      SAY_FORMATTER = "%<operation>12s  %<path>s\n".freeze

      # @since x.x.x
      # @api private
      class Renderer
        TRIM_MODE = "-".freeze

        def initialize
          freeze
        end

        def call(template, context)
          ::ERB.new(template, nil, TRIM_MODE).result(context)
        end
      end

      # @since x.x.x
      # @api private
      attr_reader :files

      # @since x.x.x
      # @api private
      attr_reader :out

      # @since x.x.x
      # @api private
      def render(path, context)
        template = File.read(path)
        renderer = Renderer.new

        renderer.call(template, context.binding)
      end

      # @since x.x.x
      # @api private
      def say(operation, path)
        out.puts(SAY_FORMATTER % { operation: operation, path: path }) # rubocop:disable Style/FormatString
      end
    end
  end
end
