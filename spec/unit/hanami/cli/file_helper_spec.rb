require "hanami/cli/file_helper"

RSpec.describe Hanami::CLI::FileHelper do
  let(:stdout) { instance_double(IO) }
  let(:files) { class_double(Hanami::Utils::Files) }
  let(:source_dir) { "tmp/file_helper_test/templates" }
  let(:destination_dir) { "tmp/file_helper_test/output" }

  subject do
    Hanami::CLI::FileHelper.new(
      out: stdout,
      files: files,
      templates_dir: source_dir
    )
  end

  describe "#create" do
    let(:context) { double(binding: nil) }

    it "creates file" do
      destination = File.join(destination_dir, "Gemfile")
      source = Pathname.new(source_dir).join("Gemfile.erb")
      expect(File).to receive(:read).with(source) { "My fake template" }
      expect(files).to receive(:write).with(destination, "My fake template")
      expect(stdout).to receive(:puts).with(
        "      create  tmp/file_helper_test/output/Gemfile\n"
      )
      subject.create("Gemfile.erb", destination, context)
    end
  end

  describe "#touch" do
    it "touches destination" do
      destination = File.join(destination_dir, ".keep")
      expect(files).to receive(:touch).with(destination)
      expect(stdout).to receive(:puts).with(
        "      create  tmp/file_helper_test/output/.keep\n"
      )
      subject.touch(destination)
    end
  end

  describe "#copy" do
    it "copies file" do
      destination = File.join(destination_dir, "Gemfile")
      source = Pathname.new(source_dir).join("Gemfile")
      expect(files).to receive(:cp).with(source, destination)
      expect(stdout).to receive(:puts).with(
        "      create  tmp/file_helper_test/output/Gemfile\n"
      )
      subject.copy("Gemfile", destination)
    end
  end

  describe "#delete" do
    let(:path) { File.join(destination_dir, "Gemfile") }

    it "deletes path" do
      expect(files).to receive(:delete).with(path)
      expect(stdout).to receive(:puts).with(
        "      remove  tmp/file_helper_test/output/Gemfile\n"
      )
      subject.delete(path)
    end

    describe "path doesn't exist" do
      before do
        allow(files).to receive(:exist?).with(path).and_return(false)
      end

      it "quietly allows missing path when allow_missing is true" do
        expect(files).to_not receive(:delete)
        expect(stdout).to_not receive(:puts)

        subject.delete(path, allow_missing: true)
      end

      it "raises error when allow_missing is false" do
        expect(files).to receive(:delete).and_raise(Errno::ENOENT)
        expect(stdout).to_not receive(:puts)

        expect {
          subject.delete(path, allow_missing: false)
        }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "#delete_directory" do
    let(:path) { File.join(destination_dir, "delete_me/") }

    it "deletes directory" do
      expect(files).to receive(:delete_directory).with(path)
      expect(stdout).to receive(:puts).with(
        "      remove  tmp/file_helper_test/output/delete_me/\n"
      )
      subject.delete_directory(path)
    end

    describe "path doesn't exist" do
      before do
        allow(files).to receive(:exist?).with(path).and_return(false)
      end

      it "quietly allows missing path when allow_missing is true" do
        expect(files).to_not receive(:delete_directory)
        expect(stdout).to_not receive(:puts)

        subject.delete_directory(path, allow_missing: true)
      end

      it "raises error when allow_missing is false" do
        expect(files).to receive(:delete_directory).and_raise(Errno::ENOENT)
        expect(stdout).to_not receive(:puts)

        expect {
          subject.delete_directory(path, allow_missing: false)
        }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "altering existing files" do
    let(:path) { File.join(destination_dir, "Gemfile") }
    let(:content) { "gemspec" }

    describe "#remove_line" do
      it "removes line file from file" do
        expect(files).to receive(:remove_line).with(path, "gemspec")
        expect(stdout).to receive(:puts).with(
          "    subtract  tmp/file_helper_test/output/Gemfile\n"
        )
        subject.remove_line(path, content)
      end
    end

    describe "#insert_after_first" do
      it "injects line after first instance of specified line" do
        expect(files).to receive(:inject_line_after).with(
          path,
          "# after me",
          "# inserted line"
        )
        expect(stdout).to receive(:puts).with(
          "      insert  tmp/file_helper_test/output/Gemfile\n"
        )
        subject.insert_after_first(path, "# inserted line", after: "# after me")
      end
    end

    describe "#insert_after_last" do
      it "injects line after last instance of specified line" do
        expect(files).to receive(:inject_line_after_last).with(
          path,
          "# after me",
          "# inserted line"
        )
        expect(stdout).to receive(:puts).with(
          "      insert  tmp/file_helper_test/output/Gemfile\n"
        )
        subject.insert_after_last(path, "# inserted line", after: "# after me")
      end
    end
  end
end
