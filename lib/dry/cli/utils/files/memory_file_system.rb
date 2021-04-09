# frozen_string_literal: true

require "dry/cli/utils/path"

module Dry
  class CLI
    module Utils
      class Files
        # Memory File System abstraction to support `Dry::CLI::Utils::Files`
        #
        # @since x.x.x
        # @api private
        class MemoryFileSystem
          require_relative "./memory_file_system/node"

          def initialize(root: Node.new)
            @root = root
          end

          def join(*path)
            Path[path]
          end

          def chdir(path)
            path = Path[path]
            directory = find_directory(path)
            raise ArgumentError, "`#{path}' isn't a directory" if directory.nil?

            current_root = @root
            @root = directory
            yield
          ensure
            @root = current_root
          end

          def mkdir(path)
            path = Path[path]
            node = @root

            for_each_segment(path) do |segment|
              node = node.put(segment)
            end
          end

          def mkdir_p(path)
            path = Path[path]

            mkdir(
              ::File.dirname(path)
            )
          end

          EMPTY_CONTENT = nil
          private_constant :EMPTY_CONTENT

          def open(path, *, &blk)
            file = write(path, EMPTY_CONTENT)
            blk.call(file)
          end

          def read(path)
            path = Path[path]
            file = find_file(path)
            raise ArgumentError, "`#{path}' isn't a file" if file.nil?

            file.content
          end

          def write(path, *content)
            path = Path[path]
            node = @root

            for_each_segment(path) do |segment|
              node = node.put(segment)
            end

            node.file!(*content)
            node
          end

          def exist?(path)
            path = Path[path]

            !find(path).nil?
          end

          def directory?(path)
            path = Path[path]
            !find_directory(path).nil?
          end

          private

          def for_each_segment(path, &blk)
            segments = path.split(::File::SEPARATOR)
            segments.each(&blk)
          end

          def find_directory(path)
            node = find(path)

            return if node.nil?
            return unless node.directory?

            node
          end

          def find_file(path)
            node = find(path)

            return if node.nil?
            return unless node.file?

            node
          end

          def find(path)
            node = @root

            for_each_segment(path) do |segment|
              break unless node

              node = node.get(segment)
            end

            node
          end
        end
      end
    end
  end
end
