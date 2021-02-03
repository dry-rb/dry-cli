# frozen_string_literal: true

RSpec.describe Dry::CLI::Inflector do
  describe ".dasherize" do
    it "returns nil if input is nil" do
      expect(described_class.dasherize(nil)).to be(nil)
    end

    it "downcases input" do
      expect(described_class.dasherize("Dry")).to eq("dry")
      expect(described_class.dasherize("CLI")).to eq("cli")
    end

    it "replaces spaces with dashes" do
      expect(described_class.dasherize("Command Line Interface")).to eq("command-line-interface")
    end

    it "replaces underscores with dashes" do
      expect(described_class.dasherize("fast_code_reloading")).to eq("fast-code-reloading")
    end

    it "accepts any object that respond to #to_s" do
      expect(described_class.dasherize(:dry)).to eq("dry")
    end
  end
end
