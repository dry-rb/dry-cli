# frozen_string_literal: true

require "dry/cli/utils/files"
require "securerandom"
require "English"

RSpec.describe Dry::CLI::Utils::Files do
  let(:root) { Pathname.new(Dir.pwd).join("tmp", SecureRandom.uuid).tap(&:mkpath) }
  let(:newline) { $INPUT_RECORD_SEPARATOR }

  after do
    FileUtils.remove_entry_secure(root)
  end

  describe "#touch" do
    it "creates an empty file" do
      path = root.join("touch")
      subject.touch(path)

      expect(path).to exist
      expect(path).to have_content("")
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "file", "touch")
      subject.touch(path)

      expect(path).to exist
      expect(path).to have_content("")
    end

    it "leaves untouched existing file" do
      path = root.join("touch")
      path.open("wb+") { |p| p.write("foo") }
      subject.touch(path)

      expect(path).to exist
      expect(path).to have_content("foo")
    end
  end

  describe "#write" do
    it "creates an file with given contents" do
      path = root.join("write")
      subject.write(path, "Hello#{newline}World")

      expect(path).to exist
      expect(path).to have_content("Hello#{newline}World")
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "file", "write")
      subject.write(path, ":)")

      expect(path).to exist
      expect(path).to have_content(":)")
    end

    it "overwrites file when it already exists" do
      path = root.join("write")
      subject.write(path, "many many many many words")
      subject.write(path, "new words")

      expect(path).to exist
      expect(path).to have_content("new words")
    end
  end

  describe "#cp" do
    let(:source) { root.join("..", "source") }

    before do
      source.delete if source.exist?
    end

    it "creates a file with given contents" do
      subject.write(source, "the source")

      destination = root.join("cp")
      subject.cp(source, destination)

      expect(destination).to exist
      expect(destination).to have_content("the source")
    end

    it "creates intermediate directories" do
      source = root.join("..", "source")
      subject.write(source, "the source for intermediate directories")

      destination = root.join("cp", "destination")
      subject.cp(source, destination)

      expect(destination).to exist
      expect(destination).to have_content("the source for intermediate directories")
    end

    it "overrides already existing file" do
      source = root.join("..", "source")
      subject.write(source, "the source")

      destination = root.join("cp")
      subject.write(destination, "the destination")
      subject.cp(source, destination)

      expect(destination).to exist
      expect(destination).to have_content("the source")
    end
  end

  describe "#mkdir" do
    it "creates directory" do
      path = root.join("mkdir")
      subject.mkdir(path)

      expect(path).to be_directory
    end

    it "creates intermediate directories" do
      path = root.join("path", "to", "mkdir")
      subject.mkdir(path)

      expect(path).to be_directory
    end
  end

  describe "#mkdir_p" do
    it "creates directory" do
      directory = root.join("mkdir_p")
      path = directory.join("file.rb")
      subject.mkdir_p(path)

      expect(directory).to be_directory
      expect(path).to_not  exist
    end

    it "creates intermediate directories" do
      directory = root.join("path", "to", "mkdir_p")
      path = directory.join("file.rb")
      subject.mkdir_p(path)

      expect(directory).to be_directory
      expect(path).to_not  exist
    end
  end

  describe "#delete" do
    it "deletes path" do
      path = root.join("delete", "file")
      subject.touch(path)
      subject.delete(path)

      expect(path).to_not exist
    end

    it "raises error if path doesn't exist" do
      path = root.join("delete", "file")

      expect { subject.delete(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#delete_directory" do
    it "deletes directory" do
      path = root.join("delete", "directory")
      subject.mkdir(path)
      subject.delete_directory(path)

      expect(path).to_not exist
    end

    it "raises error if directory doesn't exist" do
      path = root.join("delete", "directory")

      expect { subject.delete_directory(path) }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#unshift" do
    it "adds a line at the top of the file" do
      path = root.join("unshift.rb")
      content = <<~CONTENT
        class Unshift
        end
      CONTENT

      subject.write(path, content)
      subject.unshift(path, "# frozen_string_literal: true")

      expected = <<~CONTENT
        # frozen_string_literal: true
        class Unshift
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    # https://github.com/hanami/utils/issues/348
    it "adds a line at the top of a file that doesn't end with a newline" do
      path = root.join("unshift_missing_newline.rb")
      content = "get '/tires', to: 'sunshine#index'"

      subject.write(path, content)
      subject.unshift(path, "root to: 'home#index'")

      expected = "root to: 'home#index'#{newline}get '/tires', to: 'sunshine#index'"

      expect(path).to have_content(expected)
    end

    it "raises error if path doesn't exist" do
      path = root.join("unshift_no_exist.rb")

      expect { subject.unshift(path, "# frozen_string_literal: true") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#append" do
    it "adds a line at the bottom of the file" do
      path = root.join("append.rb")
      content = <<~CONTENT
        class Append
        end
      CONTENT

      subject.write(path, content)
      subject.append(path, "#{newline}Foo.register Append")

      expected = <<~CONTENT
        class Append
        end

        Foo.register Append
      CONTENT

      expect(path).to have_content(expected)
    end

    # https://github.com/hanami/utils/issues/348
    it "adds a line at the bottom of a file that doesn't end with a newline" do
      path = root.join("append_missing_newline.rb")
      content = "root to: 'home#index'"

      subject.write(path, content)
      subject.append(path, "get '/tires', to: 'sunshine#index'")

      expected = <<~CONTENT
        root to: 'home#index'
        get '/tires', to: 'sunshine#index'
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if path doesn't exist" do
      path = root.join("append_no_exist.rb")

      expect { subject.append(path, "#{newline} Foo.register Append") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#replace_first_line" do
    it "replaces string target with replacement" do
      path = root.join("replace_string.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_first_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class Replace
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces regexp target with replacement" do
      path = root.join("replace_regexp.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_first_line(path, /perform/, "  def self.call(input)")

      expected = <<~CONTENT
        class Replace
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces only the first occurrence of target with replacement" do
      path = root.join("replace_first.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end

          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_first_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class Replace
          def self.call(input)
          end

          def self.perform
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("replace_not_found.rb")
      content = <<~CONTENT
        class Replace
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.replace_first_line(path, "not existing target", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("replace_no_exist.rb")

      expect { subject.replace_first_line(path, "perform", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#replace_last_line" do
    it "replaces string target with replacement" do
      path = root.join("replace_last_string.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_last_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class ReplaceLast
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces regexp target with replacement" do
      path = root.join("replace_last_regexp.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_last_line(path, /perform/, "  def self.call(input)")

      expected = <<~CONTENT
        class ReplaceLast
          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "replaces only the last occurrence of target with replacement" do
      path = root.join("replace_last.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end

          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)
      subject.replace_last_line(path, "perform", "  def self.call(input)")

      expected = <<~CONTENT
        class ReplaceLast
          def self.perform
          end

          def self.call(input)
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("replace_last_not_found.rb")
      content = <<~CONTENT
        class ReplaceLast
          def self.perform
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.replace_last_line(path, "not existing target", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("replace_last_no_exist.rb")

      expect { subject.replace_last_line(path, "perform", "  def self.call(input)") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_before" do
    it "injects line before target (string)" do
      path = root.join("inject_before_string.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before(path, "call", "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line before target (regexp)" do
      path = root.join("inject_before_regexp.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before(path, /call/, "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_before_not_found.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_before(path, "not existing target", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_before_no_exist.rb")

      expect { subject.inject_line_before(path, "call", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_before_last" do
    it "injects line before last target (string)" do
      path = root.join("inject_before_last_string.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before_last(path, "call", "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          def self.call
          end
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line before last target (regexp)" do
      path = root.join("inject_before_last_regexp.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_before_last(path, /call/, "  # It performs the operation")

      expected = <<~CONTENT
        class InjectBefore
          def self.call
          end
          # It performs the operation
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_before_last_not_found.rb")
      content = <<~CONTENT
        class InjectBefore
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_before_last(path, "not existing target", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_before_last_no_exist.rb")

      expect { subject.inject_line_before_last(path, "call", "  # It performs the operation") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_after" do
    it "injects line after target (string)" do
      path = root.join("inject_after.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after(path, "call", "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line after target (regexp)" do
      path = root.join("inject_after.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after(path, /call/, "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_after_not_found.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_after(path, "not existing target", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_after_no_exist.rb")

      expect { subject.inject_line_after(path, "call", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_after_last" do
    it "injects line after last target (string)" do
      path = root.join("inject_after_last.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after_last(path, "call", "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects line after last target (regexp)" do
      path = root.join("inject_after_last.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_after_last(path, /call/, "    :result")

      expected = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
            :result
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("inject_after_last_not_found.rb")
      content = <<~CONTENT
        class InjectAfter
          def self.call
          end
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.inject_line_after_last(path, "not existing target", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("inject_after_last_no_exist.rb")

      expect { subject.inject_line_after_last(path, "call", "    :result") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#remove_line" do
    it "removes line (string)" do
      path = root.join("remove_line_string.rb")
      content = <<~CONTENT
        # frozen_string_literal: true
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_line(path, "frozen")

      expected = <<~CONTENT
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "removes line (regexp)" do
      path = root.join("remove_line_regexp.rb")
      content = <<~CONTENT
        # frozen_string_literal: true
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_line(path, /frozen/)

      expected = <<~CONTENT
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if target cannot be found in path" do
      path = root.join("remove_line_not_found.rb")
      content = <<~CONTENT
        # frozen_string_literal: true
        class RemoveLine
          def self.call
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.remove_line(path, "not existing target") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if path doesn't exist" do
      path = root.join("remove_line_no_exist.rb")

      expect { subject.remove_line(path, "frozen") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end

      expect(path).to_not exist
    end
  end

  describe "#inject_line_at_block_top" do
    it "injects line at the top of the Ruby block" do
      path = root.join("inject_line_at_block_top.rb")
      content = <<~CONTENT
        class InjectLineBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "configure", %(load_path.unshift("dir")))

      expected = <<~CONTENT
        class InjectLineBlockTop
          configure do
            load_path.unshift("dir")
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects lines at the top of the Ruby block" do
      path = root.join("inject_lines_at_block_top.rb")
      content = <<~CONTENT
        class InjectLinesBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "configure", [%(load_path.unshift("dir")), "settings.load!"])

      expected = <<~CONTENT
        class InjectLinesBlockTop
          configure do
            load_path.unshift("dir")
            settings.load!
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "injects block at the top of the Ruby block" do
      path = root.join("inject_block_at_block_top.rb")
      content = <<~CONTENT
        class InjectBlockBlockTop
          configure do
            root __dir__
          end
        end
      CONTENT

      block = <<~BLOCK
        settings do
          load!
        end
      BLOCK

      subject.write(path, content)
      subject.inject_line_at_block_top(path, "configure", block)

      expected = <<~CONTENT
        class InjectBlockBlockTop
          configure do
            settings do
              load!
            end
            root __dir__
          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if file cannot be found" do
      path = root.join("inject_line_at_block_top_missing_file.rb")

      expect {
        subject.inject_line_at_block_top(path, "configure", "")
      }.to raise_error(Errno::ENOENT)
    end

    it "raises error if Ruby block cannot be found" do
      path = root.join("inject_line_at_block_top_missing_block.rb")

      content = <<~CONTENT
        class InjectLineBlockTopMissingBlock
        end
      CONTENT

      subject.write(path, content)

      expect {
        subject.inject_line_at_block_top(path, "configure", "")
      }.to raise_error(ArgumentError, "Cannot find `configure' inside `#{path.realpath}'.")
    end
  end

  describe "#remove_block" do
    it "removes block from Ruby file" do
      path = root.join("remove_block_simple.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_block(path, "configure")

      expected = <<~CONTENT
        class RemoveBlock
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "removes nested block from Ruby file" do
      path = root.join("remove_block_simple.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__

            assets do
              sources << [
                "path/to/sources"
              ]
            end
          end
        end
      CONTENT

      subject.write(path, content)
      subject.remove_block(path, "assets")

      expected = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__

          end
        end
      CONTENT

      expect(path).to have_content(expected)
    end

    it "raises error if block cannot be found in path" do
      path = root.join("remove_block_not_found.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.remove_block(path, "not existing target") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises error if block cannot be found" do
      path = root.join("remove_block_string_simple.rb")
      content = <<~CONTENT
        class RemoveBlock
          configure do
            root __dir__
          end
        end
      CONTENT

      subject.write(path, content)

      expect { subject.remove_block(path, "not existing target") }.to raise_error do |exception|
        expect(exception).to be_kind_of(ArgumentError)
        expect(exception.message).to eq("Cannot find `not existing target' inside `#{path}'.")
      end

      expect(path).to have_content(content)
    end

    it "raises an error when the file was not found" do
      path = root.join("remove_block_not_found.rb")

      expect { subject.remove_block(path, "configure") }.to raise_error do |exception|
        expect(exception).to be_kind_of(Errno::ENOENT)
        expect(exception.message).to match("No such file or directory")
      end
    end
  end

  describe "#exist?" do
    it "returns true for file" do
      path = root.join("exist_file")
      subject.touch(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns true for directory" do
      path = root.join("exist_directory")
      subject.mkdir(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns false for non-existing file" do
      path = root.join("exist_not_found")

      expect(subject.exist?(path)).to be(false)
    end
  end

  describe "#directory?" do
    it "returns true for directory" do
      path = root.join("directory_directory")
      subject.mkdir(path)

      expect(subject.exist?(path)).to be(true)
    end

    it "returns false for file" do
      path = root.join("directory_file")
      subject.touch(path)

      expect(subject.directory?(path)).to be(false)
    end

    it "returns false for non-existing path" do
      path = root.join("directory_not_found")

      expect(subject.exist?(path)).to be(false)
    end
  end
end
