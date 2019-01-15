require 'hanami/utils/files'
require 'erb'

module Hanami
  class CLI
    # A class to help manipulate files, including:
    # - creating files from ERB templates
    # - copying files
    # - deleting files and directories
    # - inserting lines into existing files
    # - executing arbitrary shell commands (ok this is not file-related)
    #
    # @since x.x.x
    class FileHelper
      # @since x.x.x
      # @api public
      def initialize(out: $stdout, files: Utils::Files, templates_dir: __dir__)
        @files         = files
        @out           = out
        @templates_dir = Pathname.new(templates_dir)
      end

      # @since x.x.x
      # @api public
      def create(source, destination, context)
        files.write(destination, render(source, context))
        say(:create, destination)
      end

      # @since x.x.x
      # @api public
      def touch(path)
        files.touch(path)
        say(:create, path)
      end

      # @since x.x.x
      # @api public
      def copy(source, destination)
        files.cp(template_path(source), destination)
        say(:create, destination)
      end

      # @since x.x.x
      # @api public
      def delete(path, allow_missing: false)
        return if allow_missing && !files.exist?(path)

        files.delete(path)
        say(:remove, path)
      end

      # @since x.x.x
      # @api public
      def delete_directory(path, allow_missing: false)
        return if allow_missing && !files.exist?(path)

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
      def insert(path, content, after_first: nil, after_last: nil)
        raise UsageError.new("Pass in only one of either `after_first:` or `after_last:`") if after_first && after_last

        if after_first
          files.inject_line_after(path, after_first, content)
        elsif after_last
          files.inject_line_after_last(path, after_last, content)
        else
          raise UsageError.new("Pass in either `after_first:` or `after_last:`")
        end
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
        Kernel.system(command, opts)
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
      class UsageError < Error
      end

      # @since x.x.x
      # @api private
      attr_reader :files

      # @since x.x.x
      # @api private
      attr_reader :out

      # @since x.x.x
      # @api private
      attr_reader :templates_dir

      # @since x.x.x
      # @api private
      def render(path, context)
        template = File.read(template_path(path))
        renderer = Renderer.new

        renderer.call(template, context.binding)
      end

      # @since x.x.x
      # @api private
      def template_path(name)
        templates_dir.join(name)
      end

      # @since x.x.x
      # @api private
      def say(operation, path)
        out.puts(SAY_FORMATTER % { operation: operation, path: path }) # rubocop:disable Style/FormatString
      end
    end
  end
end
