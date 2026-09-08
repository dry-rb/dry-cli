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
    it "returns the sequences to erase the line and move the cursor back to its beginning" do
      expect(described_class.clear_line).to eq("\r\e[2K")
    end
  end

  describe ".reset_style" do
    it "returns the ANSI escape sequence to reset all styles" do
      expect(described_class.reset_style).to eq("\e[0m")
    end
  end

  describe ".erase_line" do
    it "returns the ANSI escape sequence to erase the entire line" do
      expect(described_class.erase_line).to eq("\e[2K")
    end
  end

  describe ".enter_alt_screen" do
    it "returns the ANSI escape sequence to switch to the alternate screen buffer" do
      expect(described_class.enter_alt_screen).to eq("\e[?1049h")
    end
  end

  describe ".exit_alt_screen" do
    it "returns the ANSI escape sequence to switch back to the main screen buffer" do
      expect(described_class.exit_alt_screen).to eq("\e[?1049l")
    end
  end

  describe ".clear_screen" do
    it "returns the sequences to erase the screen and move the cursor home" do
      expect(described_class.clear_screen).to eq("\e[2J\e[H")
    end
  end

  describe ".cursor_home" do
    it "returns the ANSI escape sequence to move the cursor to its home position" do
      expect(described_class.cursor_home).to eq("\e[H")
    end
  end

  describe ".move_to" do
    it "returns the ANSI escape sequence to move the cursor to the given row and column" do
      expect(described_class.move_to(3, 10)).to eq("\e[3;10H")
    end
  end

  describe ".cursor_up" do
    it "defaults to moving up one line" do
      expect(described_class.cursor_up).to eq("\e[1A")
    end

    it "returns the ANSI escape sequence to move the cursor up by the given number of lines" do
      expect(described_class.cursor_up(3)).to eq("\e[3A")
    end
  end

  describe ".cursor_down" do
    it "defaults to moving down one line" do
      expect(described_class.cursor_down).to eq("\e[1B")
    end

    it "returns the ANSI escape sequence to move the cursor down by the given number of lines" do
      expect(described_class.cursor_down(3)).to eq("\e[3B")
    end
  end

  describe ".cursor_forward" do
    it "defaults to moving forward one column" do
      expect(described_class.cursor_forward).to eq("\e[1C")
    end

    it "returns the ANSI escape sequence to move the cursor forward by the given number of columns" do
      expect(described_class.cursor_forward(3)).to eq("\e[3C")
    end
  end

  describe ".cursor_back" do
    it "defaults to moving back one column" do
      expect(described_class.cursor_back).to eq("\e[1D")
    end

    it "returns the ANSI escape sequence to move the cursor back by the given number of columns" do
      expect(described_class.cursor_back(3)).to eq("\e[3D")
    end
  end

  describe ".cursor_to_col" do
    it "returns the ANSI escape sequence to move the cursor to the given column" do
      expect(described_class.cursor_to_col(10)).to eq("\e[10G")
    end
  end

  describe ".save_cursor" do
    it "returns the ANSI escape sequence to save the cursor position" do
      expect(described_class.save_cursor).to eq("\e7")
    end
  end

  describe ".restore_cursor" do
    it "returns the ANSI escape sequence to restore the cursor position" do
      expect(described_class.restore_cursor).to eq("\e8")
    end
  end

  describe ".scroll_region" do
    it "returns the ANSI escape sequence to set the scrolling region" do
      expect(described_class.scroll_region(2, 24)).to eq("\e[2;24r")
    end
  end

  describe ".reset_scroll_region" do
    it "returns the ANSI escape sequence to reset the scrolling region" do
      expect(described_class.reset_scroll_region).to eq("\e[r")
    end
  end

  describe "constants" do
    it "exposes the raw escape sequences" do
      expect(described_class::CIVIS).to eq("\e[?25l")
      expect(described_class::CNORM).to eq("\e[?25h")
      expect(described_class::CR).to eq("\r")
      expect(described_class::EL2).to eq("\e[2K")
      expect(described_class::SGR0).to eq("\e[0m")
      expect(described_class::SMCUP).to eq("\e[?1049h")
      expect(described_class::RMCUP).to eq("\e[?1049l")
      expect(described_class::ERASE_SCREEN).to eq("\e[2J")
      expect(described_class::HOME).to eq("\e[H")
      expect(described_class::CUP).to eq("\e[%d;%dH")
      expect(described_class::CUU).to eq("\e[%dA")
      expect(described_class::CUD).to eq("\e[%dB")
      expect(described_class::CUF).to eq("\e[%dC")
      expect(described_class::CUB).to eq("\e[%dD")
      expect(described_class::CHA).to eq("\e[%dG")
      expect(described_class::SC).to eq("\e7")
      expect(described_class::RC).to eq("\e8")
      expect(described_class::CSR).to eq("\e[%d;%dr")
      expect(described_class::RESET_SCROLL_REGION).to eq("\e[r")
    end
  end
end
