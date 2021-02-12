# frozen_string_literal: true

require "fileutils"

module Dry
  class CLI
    module Utils
      class Files
        # File System abstraction to support `Dry::CLI::Utils::Files`
        #
        # @since x.x.x
        # @api private
        class FileSystem
          # Creates a new instance
          #
          # @param file [Class]
          # @param file_utils [Class]
          #
          # @return [Dry::CLI::Utils::Files::FileSystem]
          #
          # @since x.x.x
          def initialize(file: File, file_utils: FileUtils)
            @file = file
            @file_utils = file_utils
          end

          # Updates modification time (mtime) and access time (atime) of file(s)
          # in list.
          #
          # Files are created if they don’t exist.
          #
          # @see https://ruby-doc.org/stdlib/libdoc/fileutils/rdoc/FileUtils.html#method-c-touch
          #
          # @param path [String, Array<String>] the target path
          #
          # @since x.x.x
          # @api private
          def touch(path, **kwargs)
            file_utils.touch(path, **kwargs)
          end

          # Copies file content from `source` to `destination`
          #
          # @see https://ruby-doc.org/stdlib/libdoc/fileutils/rdoc/FileUtils.html#method-c-cp
          #
          # @param source [String] the file(s) or directory to copy
          # @param destination [String] the directory destination
          #
          # @since x.x.x
          # @api private
          def cp(source, destination, **kwargs)
            file_utils.cp(source, destination, **kwargs)
          end

          # Creates a directory and all its parent directories.
          #
          # The argument `path` is intended to be a **directory** that you want to
          # explicitly create.
          #
          # @see #mkdir_p
          # @see https://ruby-doc.org/stdlib/libdoc/fileutils/rdoc/FileUtils.html#method-c-mkdir_p
          #
          # @param path [String] the directory to create
          #
          # @example
          #   require "dry/cli/utils/files/file_system"
          #
          #   fs = Dry::CLI::Utils::Files::FileSystem.new
          #   fs.mkdir("/usr/var/project")
          #   # creates all the directory structure (/usr/var/project)
          #
          # @since x.x.x
          # @api private
          def mkdir(path, **kwargs)
            file_utils.mkdir_p(path, **kwargs)
          end

          # Creates a directory and all its parent directories.
          #
          # The argument `path` is intended to be a **file**, where its
          # directory ancestors will be implicitly created.
          #
          # @see #mkdir
          # @see https://ruby-doc.org/stdlib/libdoc/fileutils/rdoc/FileUtils.html#method-c-mkdir
          #
          # @param path [String] the file that will be in the directories that
          #                      this method creates
          # @example
          #   require "dry/cli/utils/files/file_system"
          #
          #   fs = Dry::CLI::Utils::Files::FileSystem.new
          #   fs.mkdir("/usr/var/project/file.rb")
          #   # creates all the directory structure (/usr/var/project)
          #   # where file.rb will eventually live
          #
          # @since x.x.x
          # @api private
          def mkdir_p(path, **kwargs)
            mkdir(
              file.dirname(path), **kwargs
            )
          end

          # Removes (deletes) a file
          #
          # @see https://ruby-doc.org/stdlib/libdoc/fileutils/rdoc/FileUtils.html#method-c-rm
          #
          # @param path [String] the file to remove
          #
          # @since x.x.x
          # @api private
          def rm(path, **kwargs)
            file_utils.rm(path, **kwargs)
          end

          # Removes (deletes) a directory
          #
          # @see https://ruby-doc.org/stdlib/libdoc/fileutils/rdoc/FileUtils.html#method-c-remove_entry_secure
          #
          # @param path [String] the directory to remove
          #
          # @since x.x.x
          # @api private
          def rm_rf(path, *args)
            file_utils.remove_entry_secure(path, *args)
          end

          # Reads the entire file specified by name as individual lines,
          # and returns those lines in an array
          #
          # @see https://ruby-doc.org/core/IO.html#method-c-readlines
          #
          # @param path [String] the file to read
          #
          # @since x.x.x
          # @api private
          def readlines(path, *args)
            file.readlines(path, *args)
          end

          # Check if the given file exist.
          #
          # @see https://ruby-doc.org/core/File.html#method-c-exist-3F
          #
          # @param path [String] the file to check
          #
          # @since x.x.x
          # @api private
          def exist?(path)
            file.exist?(path)
          end

          # Check if the given path is a directory.
          #
          # @see https://ruby-doc.org/core/File.html#method-c-directory-3F
          #
          # @param path [String] the directory to check
          #
          # @since x.x.x
          # @api private
          def directory?(path)
            file.directory?(path)
          end

          # Opens (or creates) a new file for read/write operations.
          #
          # @see https://ruby-doc.org/core/File.html#method-c-open
          #
          # @param path [String] the target file
          #
          # @since x.x.x
          # @api private
          def open(path, *args, &blk)
            file.open(path, *args, &blk)
          end

          private

          # @since x.x.x
          # @api private
          attr_reader :file

          # @since x.x.x
          # @api private
          attr_reader :file_utils
        end
      end
    end
  end
end
