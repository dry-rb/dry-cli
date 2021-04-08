# frozen_string_literal: true

require "dry/cli/utils/path"

RSpec.describe Dry::CLI::Utils::Path do
  describe ".call" do
    let(:unix_file_separator) { "/" }
    let(:windows_file_separator) { '\\' }

    context "when string" do
      it "recombines given path with system file separator" do
        tokens = ["path", "to", "file"]
        expected = tokens.join(::File::SEPARATOR)

        expect(described_class.call(tokens.join(unix_file_separator))).to eq(expected)
        expect(described_class.call(tokens.join(windows_file_separator))).to eq(expected)
      end
    end

    context "when array" do
      it "recombines given path with system file separator" do
        tokens = ["path", "to", "file"]
        expected = tokens.join(::File::SEPARATOR)

        expect(described_class.call(tokens)).to eq(expected)
      end
    end

    context "when splat arguments" do
      it "recombines given path with system file separator" do
        tokens = ["path", ["to", "file"]]
        expected = tokens.flatten.join(::File::SEPARATOR)

        expect(described_class.call(*tokens)).to eq(expected)
      end
    end
  end
end
