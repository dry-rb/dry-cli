# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'backports/2.4.0/string/match' if RUBY_VERSION < '2.4'

module Dry
  class CLI
    module Utils
      # Files utilities
      #
      # @since 0.3.1
      module Files # rubocop:disable Metrics/ModuleLength
        # Creates an empty file for the given path.
        # All the intermediate directories are created.
        # If the path already exists, it doesn't change the contents
        #
        # @param path [String,Pathname] the path to file
        #
        # @since 0.3.1
        def self.touch(path)
          mkdir_p(path)
          FileUtils.touch(path)
        end

        # Creates a new file or rewrites the contents
        # of an existing file for the given path and content
        # All the intermediate directories are created.
        #
        # @param path [String,Pathname] the path to file
        # @param content [String, Array<String>] the content to write
        #
        # @since 0.3.1
        def self.write(path, *content)
          mkdir_p(path)
          open(path, ::File::CREAT | ::File::WRONLY | ::File::TRUNC, *content) # rubocop:disable LineLength, Security/Open - this isn't a call to `::Kernel.open`, but to `self.open`
        end

        # Copies source into destination.
        # All the intermediate directories are created.
        # If the destination already exists, it overrides the contents.
        #
        # @param source [String,Pathname] the path to the source file
        # @param destination [String,Pathname] the path to the destination file
        #
        # @since 0.3.1
        def self.cp(source, destination)
          mkdir_p(destination)
          FileUtils.cp(source, destination)
        end

        # Creates a directory for the given path.
        # It assumes that all the tokens in `path` are meant to be a directory.
        # All the intermediate directories are created.
        #
        # @param path [String,Pathname] the path to directory
        #
        # @since 0.3.1
        #
        # @see .mkdir_p
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.mkdir("path/to/directory")
        #     # => creates the `path/to/directory` directory
        #
        #   # WRONG this isn't probably what you want, check `.mkdir_p`
        #   Dry::CLI::Utils::Files.mkdir("path/to/file.rb")
        #     # => creates the `path/to/file.rb` directory
        def self.mkdir(path)
          FileUtils.mkdir_p(path)
        end

        # Creates a directory for the given path.
        # It assumes that all the tokens, but the last, in `path` are meant to be
        # a directory, whereas the last is meant to be a file.
        # All the intermediate directories are created.
        #
        # @param path [String,Pathname] the path to directory
        #
        # @since 0.3.1
        #
        # @see .mkdir
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.mkdir_p("path/to/file.rb")
        #     # => creates the `path/to` directory, but NOT `file.rb`
        #
        #   # WRONG it doesn't create the last directory, check `.mkdir`
        #   Dry::CLI::Utils::Files.mkdir_p("path/to/directory")
        #     # => creates the `path/to` directory
        def self.mkdir_p(path)
          Pathname.new(path).dirname.mkpath
        end

        # Deletes given path (file).
        #
        # @param path [String,Pathname] the path to file
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @since 0.3.1
        def self.delete(path)
          FileUtils.rm(path)
        end

        # Deletes given path (directory).
        #
        # @param path [String,Pathname] the path to file
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @since 0.3.1
        def self.delete_directory(path)
          FileUtils.remove_entry_secure(path)
        end

        # Adds a new line at the top of the file
        #
        # @param path [String,Pathname] the path to file
        # @param line [String] the line to add
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @see .append
        #
        # @since 0.3.1
        def self.unshift(path, line)
          content = ::File.readlines(path)
          content.unshift("#{line}\n")

          write(path, content)
        end

        # Adds a new line at the bottom of the file
        #
        # @param path [String,Pathname] the path to file
        # @param contents [String] the contents to add
        #
        # @raise [Errno::ENOENT] if the path doesn't exist
        #
        # @see .unshift
        #
        # @since 0.3.1
        def self.append(path, contents)
          mkdir_p(path)

          content = ::File.readlines(path)
          content << "\n" unless content.last.end_with?("\n")
          content << "#{contents}\n"

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
        # @see .replace_last_line
        #
        # @since 0.3.1
        def self.replace_first_line(path, target, replacement)
          content = ::File.readlines(path)
          content[index(content, path, target)] = "#{replacement}\n"

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
        # @see .replace_first_line
        #
        # @since 0.3.1
        def self.replace_last_line(path, target, replacement)
          content = ::File.readlines(path)
          content[-index(content.reverse, path, target) - 1] = "#{replacement}\n"

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
        # @see .inject_line_after
        # @see .inject_line_before_last
        # @see .inject_line_after_last
        #
        # @since 0.3.1
        def self.inject_line_before(path, target, contents)
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
        # @see .inject_line_before
        # @see .inject_line_after
        # @see .inject_line_after_last
        #
        # @since 1.3.0
        def self.inject_line_before_last(path, target, contents)
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
        # @see .inject_line_before
        # @see .inject_line_before_last
        # @see .inject_line_after_last
        #
        # @since 0.3.1
        def self.inject_line_after(path, target, contents)
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
        # @see .inject_line_before
        # @see .inject_line_after
        # @see .inject_line_before_last
        # @see .inject_line_after_last
        #
        # @since 1.3.0
        def self.inject_line_after_last(path, target, contents)
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
        # @since 0.3.1
        def self.remove_line(path, target)
          content = ::File.readlines(path)
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
        # @since 0.3.1
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
        #   Dry::CLI::Utils::Files.remove_block("app.rb", "configure")
        #
        #   puts File.read("app.rb")
        #
        #   # class App
        #   # end
        def self.remove_block(path, target)
          content  = ::File.readlines(path)
          starting = index(content, path, target)
          line     = content[starting]
          size     = line[/\A[[:space:]]*/].bytesize
          closing  = (' ' * size) + (target.match?(/{/) ? '}' : 'end')
          ending   = starting + index(content[starting..-1], path, closing)

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
        # @since 0.3.1
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.exist?(__FILE__) # => true
        #   Dry::CLI::Utils::Files.exist?(__dir__)  # => true
        #
        #   Dry::CLI::Utils::Files.exist?("missing_file") # => false
        def self.exist?(path)
          File.exist?(path)
        end

        # Checks if `path` is a directory
        #
        # @param path [String,Pathname] the path to directory
        #
        # @return [TrueClass,FalseClass] the result of the check
        #
        # @since 0.3.1
        #
        # @example
        #   require "dry/cli/utils/files"
        #
        #   Dry::CLI::Utils::Files.directory?(__dir__)  # => true
        #   Dry::CLI::Utils::Files.directory?(__FILE__) # => false
        #
        #   Dry::CLI::Utils::Files.directory?("missing_directory") # => false
        def self.directory?(path)
          File.directory?(path)
        end

        # private

        # @since 0.3.1
        # @api private
        def self.match?(content, target)
          !line_number(content, target).nil?
        end

        private_class_method :match?

        # @since 0.3.1
        # @api private
        def self.open(path, mode, *content)
          ::File.open(path, mode) do |file|
            file.write(Array(content).flatten.join)
          end
        end

        private_class_method :open

        # @since 0.3.1
        # @api private
        def self.index(content, path, target)
          line_number(content, target) ||
            raise(ArgumentError, "Cannot find `#{target}' inside `#{path}'.")
        end

        private_class_method :index

        # @since 1.3.0
        # @api private
        def self.rindex(content, path, target)
          line_number(content, target, finder: content.method(:rindex)) ||
            raise(ArgumentError, "Cannot find `#{target}' inside `#{path}'.")
        end

        private_class_method :rindex

        # @since 1.3.0
        # @api private
        def self._inject_line_before(path, target, contents, finder)
          content = ::File.readlines(path)
          i       = finder.call(content, path, target)

          content.insert(i, "#{contents}\n")
          write(path, content)
        end

        private_class_method :_inject_line_before

        # @since 1.3.0
        # @api private
        def self._inject_line_after(path, target, contents, finder)
          content = ::File.readlines(path)
          i       = finder.call(content, path, target)

          content.insert(i + 1, "#{contents}\n")
          write(path, content)
        end

        private_class_method :_inject_line_after

        # @since 0.3.1
        # @api private
        def self.line_number(content, target, finder: content.method(:index))
          finder.call do |l|
            case target
            when ::String
              l.include?(target)
            when Regexp
              l =~ target
            end
          end
        end

        private_class_method :line_number
      end
    end
  end
end
