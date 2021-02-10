# frozen_string_literal: true

module Dry
  class CLI
    module Utils
      # Files utilities
      #
      # @since 0.3.1
      class Files
        require_relative "./files/file_system"

        # Creates a new instance
        #
        # @param file [Class]
        # @param file_utils [Class]
        #
        # @return [Dry::CLI::Utils::Files]
        #
        # @since x.x.x
        def initialize(file_system: FileSystem.new)
          @file_system = file_system
        end

        # Creates an empty file for the given path.
        # All the intermediate directories are created.
        # If the path already exists, it doesn't change the contents
        #
        # @param path [String,Pathname] the path to file
        #
        # @since x.x.x
        def touch(path)
          mkdir_p(path)
          file_system.touch(path)
        end

        # Creates a new file or rewrites the contents
        # of an existing file for the given path and content
        # All the intermediate directories are created.
        #
        # @param path [String,Pathname] the path to file
        # @param content [String, Array<String>] the content to write
        #
        # @since x.x.x
        def write(path, *content)
          mkdir_p(path)
          open(path, WRITE_MODE, *content) # rubocop:disable Security/Open - this isn't a call to `::Kernel.open`, but to `self.open`
        end

        # Copies source into destination.
        # All the intermediate directories are created.
        # If the destination already exists, it overrides the contents.
        #
        # @param source [String,Pathname] the path to the source file
        # @param destination [String,Pathname] the path to the destination file
        #
        # @since x.x.x
        def cp(source, destination)
          mkdir_p(destination)
          file_system.cp(source, destination)
        end

        # Creates a directory for the given path.
        # It assumes that all the tokens in `path` are meant to be a directory.
        # All the intermediate directories are created.
        #
        # @param path [String,Pathname] the path to directory
        #
        # @since x.x.x
        #
        # @see #mkdir_p
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.new.mkdir("path/to/directory")
        #     # => creates the `path/to/directory` directory
        #
        #   # WRONG this isn't probably what you want, check `.mkdir_p`
        #   Dry::CLI::Utils::Files.new.mkdir("path/to/file.rb")
        #     # => creates the `path/to/file.rb` directory
        def mkdir(path)
          file_system.mkdir(path)
        end

        # Creates a directory for the given path.
        # It assumes that all the tokens, but the last, in `path` are meant to be
        # a directory, whereas the last is meant to be a file.
        # All the intermediate directories are created.
        #
        # @param path [String,Pathname] the path to directory
        #
        # @since x.x.x
        #
        # @see #mkdir
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.new.mkdir_p("path/to/file.rb")
        #     # => creates the `path/to` directory, but NOT `file.rb`
        #
        #   # WRONG it doesn't create the last directory, check `.mkdir`
        #   Dry::CLI::Utils::Files.new.mkdir_p("path/to/directory")
        #     # => creates the `path/to` directory
        def mkdir_p(path)
          file_system.mkdir_p(path)
        end

        # Deletes given path (file).
        #
        # @param path [String,Pathname] the path to file
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @since x.x.x
        def delete(path)
          file_system.rm(path)
        end

        # Deletes given path (directory).
        #
        # @param path [String,Pathname] the path to file
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @since x.x.x
        def delete_directory(path)
          file_system.rm_rf(path)
        end

        # Adds a new line at the top of the file
        #
        # @param path [String,Pathname] the path to file
        # @param line [String] the line to add
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @see #append
        #
        # @since x.x.x
        def unshift(path, line)
          content = file_system.readlines(path)
          content.unshift(newline(line))

          write(path, content)
        end

        # Adds a new line at the bottom of the file
        #
        # @param path [String,Pathname] the path to file
        # @param contents [String] the contents to add
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @see #unshift
        #
        # @since x.x.x
        def append(path, contents)
          mkdir_p(path)

          content = file_system.readlines(path)
          content << newline unless newline?(content.last)
          content << newline(contents)

          write(path, content)
        end

        # Replace first line in `path` that contains `target` with `replacement`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to replace
        # @param replacement [String] the replacement
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @see #replace_last_line
        #
        # @since x.x.x
        def replace_first_line(path, target, replacement)
          content = file_system.readlines(path)
          content[index(content, path, target)] = newline(replacement)

          write(path, content)
        end

        # Replace last line in `path` that contains `target` with `replacement`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to replace
        # @param replacement [String] the replacement
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @see #replace_first_line
        #
        # @since x.x.x
        def replace_last_line(path, target, replacement)
          content = file_system.readlines(path)
          content[-index(content.reverse, path, target) - CONTENT_OFFSET] = newline(replacement)

          write(path, content)
        end

        # Inject `contents` in `path` before `target`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to replace
        # @param contents [String] the contents to inject
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @see #inject_line_after
        # @see #inject_line_before_last
        # @see #inject_line_after_last
        #
        # @since x.x.x
        def inject_line_before(path, target, contents)
          _inject_line_before(path, target, contents, method(:index))
        end

        # Inject `contents` in `path` after last `target`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to replace
        # @param contents [String] the contents to inject
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @see #inject_line_before
        # @see #inject_line_after
        # @see #inject_line_after_last
        #
        # @since x.x.x
        def inject_line_before_last(path, target, contents)
          _inject_line_before(path, target, contents, method(:rindex))
        end

        # Inject `contents` in `path` after `target`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to replace
        # @param contents [String] the contents to inject
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @see #inject_line_before
        # @see #inject_line_before_last
        # @see #inject_line_after_last
        #
        # @since x.x.x
        def inject_line_after(path, target, contents)
          _inject_line_after(path, target, contents, method(:index))
        end

        # Inject `contents` in `path` after last `target`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to replace
        # @param contents [String] the contents to inject
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @see #inject_line_before
        # @see #inject_line_after
        # @see #inject_line_before_last
        #
        # @since x.x.x
        def inject_line_after_last(path, target, contents)
          _inject_line_after(path, target, contents, method(:rindex))
        end

        # Removes line from `path`, matching `target`.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target to remove
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @since x.x.x
        def remove_line(path, target)
          content = file_system.readlines(path)
          i       = index(content, path, target)

          content.delete_at(i)
          write(path, content)
        end

        # Removes `target` block from `path`
        #
        # @param path [String,Pathname] the path to file
        # @param target [String] the target block to remove
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @since x.x.x
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   puts File.read("app.rb")
        #
        #   # class App
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   Dry::CLI::Utils::Files.new.remove_block("app.rb", "configure")
        #
        #   puts File.read("app.rb")
        #
        #   # class App
        #   # end
        def remove_block(path, target)
          content  = file_system.readlines(path)
          starting = index(content, path, target)
          line     = content[starting]
          size     = line[SPACE_MATCHER].bytesize
          closing  = (SPACE * size) +
                     (target.match?(INLINE_OPEN_BLOCK_MATCHER) ? INLINE_CLOSE_BLOCK : CLOSE_BLOCK)
          ending   = starting + index(content[starting..-CONTENT_OFFSET], path, closing)

          content.slice!(starting..ending)
          write(path, content)

          remove_block(path, target) if match?(content, target)
        end

        # Checks if `path` exist
        #
        # @param path [String,Pathname] the path to file
        #
        # @return [TrueClass,FalseClass] the result of the check
        #
        # @since x.x.x
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.new.exist?(__FILE__) # => true
        #   Dry::CLI::Utils::Files.new.exist?(__dir__)  # => true
        #
        #   Dry::CLI::Utils::Files.new.exist?("missing_file") # => false
        def exist?(path)
          file_system.exist?(path)
        end

        # Checks if `path` is a directory
        #
        # @param path [String,Pathname] the path to directory
        #
        # @return [TrueClass,FalseClass] the result of the check
        #
        # @since x.x.x
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.new.directory?(__dir__)  # => true
        #   Dry::CLI::Utils::Files.new.directory?(__FILE__) # => false
        #
        #   Dry::CLI::Utils::Files.new.directory?("missing_directory") # => false
        def directory?(path)
          file_system.directory?(path)
        end

        private

        # @since x.x.x
        # @api private
        NEW_LINE = $/ # rubocop:disable Style/SpecialGlobalVars
        private_constant :NEW_LINE

        # @since x.x.x
        # @api private
        WRITE_MODE = (::File::CREAT | ::File::WRONLY | ::File::TRUNC).freeze
        private_constant :WRITE_MODE

        # @since x.x.x
        # @api private
        CONTENT_OFFSET = 1
        private_constant :CONTENT_OFFSET

        # @since x.x.x
        # @api private
        SPACE = " "
        private_constant :SPACE

        # @since x.x.x
        # @api private
        SPACE_MATCHER = /\A[[:space:]]*/.freeze
        private_constant :SPACE_MATCHER

        # @since x.x.x
        # @api private
        INLINE_OPEN_BLOCK_MATCHER = /{/.freeze
        private_constant :INLINE_OPEN_BLOCK_MATCHER

        # @since x.x.x
        # @api private
        INLINE_CLOSE_BLOCK = "}"
        private_constant :INLINE_CLOSE_BLOCK

        # @since x.x.x
        # @api private
        CLOSE_BLOCK = "end"
        private_constant :CLOSE_BLOCK

        # @since x.x.x
        # @api private
        attr_reader :file_system

        # @since x.x.x
        # @api private
        def newline(line = nil)
          "#{line}#{NEW_LINE}"
        end

        # @since x.x.x
        # @api private
        def newline?(content)
          content.end_with?(NEW_LINE)
        end

        # @since x.x.x
        # @api private
        def match?(content, target)
          !line_number(content, target).nil?
        end

        # @since x.x.x
        # @api private
        def open(path, mode, *content)
          file_system.open(path, mode) do |f|
            f.write(Array(content).flatten.join)
          end
        end

        # @since x.x.x
        # @api private
        def index(content, path, target)
          line_number(content, target) ||
            raise(ArgumentError, "Cannot find `#{target}' inside `#{path}'.")
        end

        # @since x.x.x
        # @api private
        def rindex(content, path, target)
          line_number(content, target, finder: content.method(:rindex)) ||
            raise(ArgumentError, "Cannot find `#{target}' inside `#{path}'.")
        end

        # @since x.x.x
        # @api private
        def _inject_line_before(path, target, contents, finder)
          content = file_system.readlines(path)
          i       = finder.call(content, path, target)

          content.insert(i, newline(contents))
          write(path, content)
        end

        # @since x.x.x
        # @api private
        def _inject_line_after(path, target, contents, finder)
          content = file_system.readlines(path)
          i       = finder.call(content, path, target)

          content.insert(i + CONTENT_OFFSET, newline(contents))
          write(path, content)
        end

        # @since x.x.x
        # @api private
        def line_number(content, target, finder: content.method(:index))
          finder.call do |l|
            case target
            when ::String
              l.include?(target)
            when Regexp
              l =~ target
            end
          end
        end
      end
    end
  end
end
