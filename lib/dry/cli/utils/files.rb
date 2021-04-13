# frozen_string_literal: true

module Dry
  class CLI
    module Utils
      # Files utilities
      #
      # @since 0.3.1
      class Files
        require_relative "./files/adapter"

        # Creates a new instance
        #
        # @param adapter [Dry::CLI::Utils::FileSystem]
        #
        # @return [Dry::CLI::Utils::Files]
        #
        # @since x.x.x
        def initialize(memory: false, adapter: Adapter.call(memory: memory))
          @adapter = adapter
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
          adapter.touch(path)
        end

        def read(path)
          adapter.read(path)
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
          adapter.cp(source, destination)
        end

        # Returns a new string formed by joining the strings using Operating
        # System path separator
        #
        # @param path [Array<String,Pathname>] path tokens
        #
        # @return [String] the joined path
        #
        # @since x.x.x
        def join(*path)
          adapter.join(*path)
        end

        # Converts a path to an absolute path.
        #
        # Relative paths are referenced from the current working directory of
        # the process unless `dir` is given.
        #
        # @param source [String,Pathname] the path to the file
        # @param dir [String,Pathname] the base directory
        #
        # @return [String] the expanded path
        #
        # @since x.x.x
        def expand_path(path, dir = pwd)
          adapter.expand_path(path, dir)
        end

        # Returns the name of the current working directory.
        #
        # @return [String] the current working directory.
        #
        # @since x.x.x
        def pwd
          adapter.pwd
        end

        # Temporary changes the current working directory of the process to the
        # given path and yield the given block.
        #
        # @param path [String,Pathname] the target directory
        # @param blk [Proc] the code to execute with the target directory
        #
        # @since x.x.x
        def chdir(path, &blk)
          adapter.chdir(path, &blk)
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
          adapter.mkdir(path)
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
          adapter.mkdir_p(path)
        end

        # Deletes given path (file).
        #
        # @param path [String,Pathname] the path to file
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @since x.x.x
        def delete(path)
          adapter.rm(path)
        end

        # Deletes given path (directory).
        #
        # @param path [String,Pathname] the path to file
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @since x.x.x
        def delete_directory(path)
          adapter.rm_rf(path)
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
          content = adapter.readlines(path)
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

          content = adapter.readlines(path)
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
          content = adapter.readlines(path)
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
          content = adapter.readlines(path)
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

        # Inject `contents` in `path` within the first Ruby block that matches `target`.
        # The given `contents` will appear at the TOP of the Ruby block.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target matcher for Ruby block
        # @param contents [String,Array<String>] the contents to inject
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @since x.x.x
        #
        # @example Inject a single line
        #   require "dry/cli/utils/files"
        #
        #   files = Dry::CLI::Utils::Files.new
        #   path = "config/application.rb"
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   # inject a single line
        #   files.inject_line_at_block_top(path, /configure/, %(load_path.unshift("lib")))
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     load_path.unshift("lib")
        #   #     root __dir__
        #   #   end
        #   # end
        #
        # @example Inject multiple lines
        #   require "dry/cli/utils/files"
        #
        #   files = Dry::CLI::Utils::Files.new
        #   path = "config/application.rb"
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   # inject multiple lines
        #   files.inject_line_at_block_top(path,
        #                                  /configure/,
        #                                  [%(load_path.unshift("lib")), "settings.load!"])
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     load_path.unshift("lib")
        #   #     settings.load!
        #   #     root __dir__
        #   #   end
        #   # end
        #
        # @example Inject a block
        #   require "dry/cli/utils/files"
        #
        #   files = Dry::CLI::Utils::Files.new
        #   path = "config/application.rb"
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   # inject a block
        #   block = <<~BLOCK
        #     settings do
        #       load!
        #     end
        #   BLOCK
        #   files.inject_line_at_block_top(path, /configure/, block)
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     settings do
        #   #       load!
        #   #     end
        #   #     root __dir__
        #   #   end
        #   # end
        def inject_line_at_block_top(path, target, *contents)
          content  = adapter.readlines(path)
          starting = index(content, path, target)
          offset   = SPACE * (content[starting][SPACE_MATCHER].bytesize + INDENTATION)

          contents = Array(contents).flatten
          contents = _offset_block_lines(contents, offset)

          content.insert(starting + CONTENT_OFFSET, contents)
          write(path, content)
        end

        # Inject `contents` in `path` within the first Ruby block that matches `target`.
        # The given `contents` will appear at the BOTTOM of the Ruby block.
        #
        # @param path [String,Pathname] the path to file
        # @param target [String,Regexp] the target matcher for Ruby block
        # @param contents [String,Array<String>] the contents to inject
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        # @raise [ArgumentError] if `target` cannot be found in `path`
        #
        # @since x.x.x
        #
        # @example Inject a single line
        #   require "dry/cli/utils/files"
        #
        #   files = Dry::CLI::Utils::Files.new
        #   path = "config/application.rb"
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   # inject a single line
        #   files.inject_line_at_block_bottom(path, /configure/, %(load_path.unshift("lib")))
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #     load_path.unshift("lib")
        #   #   end
        #   # end
        #
        # @example Inject multiple lines
        #   require "dry/cli/utils/files"
        #
        #   files = Dry::CLI::Utils::Files.new
        #   path = "config/application.rb"
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   # inject multiple lines
        #   files.inject_line_at_block_bottom(path,
        #                                     /configure/,
        #                                     [%(load_path.unshift("lib")), "settings.load!"])
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #     load_path.unshift("lib")
        #   #     settings.load!
        #   #   end
        #   # end
        #
        # @example Inject a block
        #   require "dry/cli/utils/files"
        #
        #   files = Dry::CLI::Utils::Files.new
        #   path = "config/application.rb"
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #   end
        #   # end
        #
        #   # inject a block
        #   block = <<~BLOCK
        #     settings do
        #       load!
        #     end
        #   BLOCK
        #   files.inject_line_at_block_bottom(path, /configure/, block)
        #
        #   File.read(path)
        #   # # frozen_string_literal: true
        #   #
        #   # class Application
        #   #   configure do
        #   #     root __dir__
        #   #     settings do
        #   #       load!
        #   #     end
        #   #   end
        #   # end
        def inject_line_at_block_bottom(path, target, *contents)
          content  = adapter.readlines(path)
          starting = index(content, path, target)
          line     = content[starting]
          size     = line[SPACE_MATCHER].bytesize
          closing  = (SPACE * size) +
                     (target.match?(INLINE_OPEN_BLOCK_MATCHER) ? INLINE_CLOSE_BLOCK : CLOSE_BLOCK)
          ending   = starting + index(content[starting..-CONTENT_OFFSET], path, closing)
          offset   = SPACE * (content[ending][SPACE_MATCHER].bytesize + INDENTATION)

          contents = Array(contents).flatten
          contents = _offset_block_lines(contents, offset)

          content.insert(ending, contents)
          write(path, content)
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
          content = adapter.readlines(path)
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
          content  = adapter.readlines(path)
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
          adapter.exist?(path)
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
          adapter.directory?(path)
        end

        # Checks if `path` is an executable
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
        #   Dry::CLI::Utils::Files.new.executable?("/path/to/ruby") # => true
        #   Dry::CLI::Utils::Files.new.executable?(__FILE__)        # => false
        #
        #   Dry::CLI::Utils::Files.new.directory?("missing_file") # => false
        def executable?(path)
          adapter.executable?(path)
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
        INDENTATION = 2
        private_constant :INDENTATION

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
        attr_reader :adapter

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
          adapter.open(path, mode) do |f|
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
          content = adapter.readlines(path)
          i       = finder.call(content, path, target)

          content.insert(i, newline(contents))
          write(path, content)
        end

        # @since x.x.x
        # @api private
        def _inject_line_after(path, target, contents, finder)
          content = adapter.readlines(path)
          i       = finder.call(content, path, target)

          content.insert(i + CONTENT_OFFSET, newline(contents))
          write(path, content)
        end

        # @since x.x.x
        # @api private
        def _offset_block_lines(contents, offset)
          contents.map do |line|
            if line.match?(NEW_LINE)
              line = line.split(NEW_LINE)
              _offset_block_lines(line, offset)
            else
              offset + line + NEW_LINE
            end
          end.join
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
