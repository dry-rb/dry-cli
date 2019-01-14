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

  describe "#copy" do
    it "creates files" do
      destination = File.join(destination_dir, "Gemfile")
      source = Pathname.new(source_dir).join("Gemfile")
      expect(files).to receive(:cp).with(source, destination)
      expect(stdout).to receive(:puts).with(
        "      create  tmp/file_helper_test/output/Gemfile\n"
      )
      subject.copy("Gemfile", destination)
    end
  end
end
