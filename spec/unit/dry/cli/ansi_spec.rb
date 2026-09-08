# frozen_string_literal: true

RSpec.describe Dry::CLI::ANSI do
  describe ".hide_cursor" do
    it "returns the ANSI escape sequence to hide the cursor" do
      expect(described_class.hide_cursor).to eq("\e[?25l")
    end
  end

  describe ".show_cursor" do
    it "returns the ANSI escape sequence to show the cursor" do
      expect(described_class.show_cursor).to eq("\e[?25h")
    end
  end

  describe ".carriage_return" do
    it "returns the carriage return control character" do
      expect(described_class.carriage_return).to eq("\r")
    end
  end

  describe ".clear_line" do
    it "returns the ANSI escape sequence to clear the entire line" do
      expect(described_class.clear_line).to eq("\e[2K")
    end
  end

  describe ".reset_style" do
    it "returns the ANSI escape sequence to reset all styles" do
      expect(described_class.reset_style).to eq("\e[0m")
    end
  end

  describe ".erase_line" do
    it "returns the sequences to clear the line and move the cursor back to its beginning" do
      expect(described_class.erase_line).to eq("\r\e[2K")
    end
  end

  describe "constants" do
    it "exposes the raw escape sequences" do
      expect(described_class::CIVIS).to eq("\e[?25l")
      expect(described_class::CNORM).to eq("\e[?25h")
      expect(described_class::CR).to eq("\r")
      expect(described_class::EL2).to eq("\e[2K")
      expect(described_class::SGR0).to eq("\e[0m")
    end
  end
end
