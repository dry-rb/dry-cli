require 'hanami/utils/files'
require 'hanami/cli/templates'
require 'erb'

module Hanami
  class CLI
    # A class to help generate files
    #
    # @since 0.1.0
    class Generator
      # @since x.x.x
      # @api public
      def initialize(out: $stdout, files: Utils::Files, root_dir: nil)
        @files     = files
        @out       = out
        @templates = Templates.new(root_dir)
      end

      # @since x.x.x
      # @api public
      def create(source, destination, context)
        files.write(destination, render(source, context))
        say(:create, destination)
      end

      # Q: Should we replace this method with `create` and passing in
      # `source` as `nil`? (and `context` too)
      # @since x.x.x
      # @api public
      def touch(path)
        files.touch(path)
        say(:create, path)
      end

      # @since x.x.x
      # @api public
      def copy(source, destination)
        files.cp(templates.find(source), destination)
        say(:create, destination)
      end

      # @since x.x.x
      # @api public
      def delete(path, allow_missing: false)
        return if allow_missing && !files.exist?(path)
        files.delete(path)
        say(:remove, path)
      end

      # TODO: add allow_missing?
      # @since x.x.x
      # @api public
      def delete_directory(path)
        files.delete_directory(path)
        say(:remove, path)
      end

      # @since x.x.x
      # @api public
      def remove_line(path, content)
        files.remove_line(path, content)
        say(:subtract, path)
      end

      # @since x.x.x
      # @api public
      def insert_after_first(path, content, after:)
        files.inject_line_after(path, after, content)
        say(:insert, path)
      end

      # @since x.x.x
      # @api public
      def insert_after_last(path, content, after:)
        files.inject_line_after_last(path, after, content)
        say(:insert, path)
      end

      # @since x.x.x
      # @api public
      def append(path, content)
        files.append(path, content)
        say(:append, path)
      end

      # @since x.x.x
      # @api public
      def execute(command, **opts)
        system(command, opts)
        say(:run, command)
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
      attr_reader :templates

      # @since x.x.x
      # @api private
      def render(path, context)
        template = File.read(templates.find(path))
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
