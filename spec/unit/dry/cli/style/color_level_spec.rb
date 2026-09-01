# frozen_string_literal: true

RSpec.describe Dry::CLI::Style::ColorLevel do
  describe ".detect" do
    def detect(env)
      described_class.detect(env)
    end

    context "FORCE_COLOR" do
      it "names the level" do
        expect(detect("FORCE_COLOR" => "0")).to eq :none
        expect(detect("FORCE_COLOR" => "1")).to eq :ansi16
        expect(detect("FORCE_COLOR" => "2")).to eq :ansi256
        expect(detect("FORCE_COLOR" => "3")).to eq :truecolor
      end

      it "accepts false as no color" do
        expect(detect("FORCE_COLOR" => "false")).to eq :none
      end

      it "wins over every other signal" do
        expect(detect("FORCE_COLOR" => "3", "TERM" => "dumb")).to eq :truecolor
        expect(detect("FORCE_COLOR" => "0", "COLORTERM" => "truecolor")).to eq :none
      end

      it "falls through to detection when it doesn't name a level" do
        expect(detect("FORCE_COLOR" => "true", "COLORTERM" => "truecolor")).to eq :truecolor
        expect(detect("FORCE_COLOR" => "", "TERM" => "xterm-256color")).to eq :ansi256
      end
    end

    context "24-bit color" do
      it "believes a terminal that announces it through COLORTERM" do
        expect(detect("COLORTERM" => "truecolor")).to eq :truecolor
        expect(detect("COLORTERM" => "24bit")).to eq :truecolor
      end

      it "is case insensitive about COLORTERM" do
        expect(detect("COLORTERM" => "TrueColor")).to eq :truecolor
      end

      it "reads a direct color TERM" do
        expect(detect("TERM" => "xterm-direct")).to eq :truecolor
        expect(detect("TERM" => "xterm-truecolor")).to eq :truecolor
      end

      it "detects Windows Terminal, which has no TERM to announce through" do
        expect(detect("WT_SESSION" => "abc")).to eq :truecolor
      end

      it "does not require knowing the terminal" do
        # The point of the convention: a terminal released after this gem still gets 24-bit
        expect(detect("TERM_PROGRAM" => "SomeTerminalNobodyHasWrittenYet",
          "TERM" => "xterm-256color",
          "COLORTERM" => "truecolor")).to eq :truecolor
      end
    end

    context "256 colors" do
      it "reads a 256 color TERM" do
        expect(detect("TERM" => "xterm-256color")).to eq :ansi256
        expect(detect("TERM" => "screen-256color")).to eq :ansi256
        expect(detect("TERM" => "tmux-256color")).to eq :ansi256
      end

      it "is case insensitive about TERM" do
        expect(detect("TERM" => "XTERM-256COLOR")).to eq :ansi256
      end

      it "settles for it when a terminal claims no more than that" do
        # Terminal.app, for one: TERM says 256, and it sets no COLORTERM because it means it
        expect(detect("TERM" => "xterm-256color", "TERM_PROGRAM" => "Apple_Terminal"))
          .to eq :ansi256
      end
    end

    context "16 colors" do
      it "assumes them for any terminal that names itself" do
        %w[xterm screen tmux rxvt linux konsole vt100 ansi wyse50 something-new].each do |term|
          expect(detect("TERM" => term)).to eq :ansi16
        end
      end
    end

    context "no color" do
      it "believes a terminal that disclaims escape sequences" do
        expect(detect("TERM" => "dumb")).to eq :none
        expect(detect("TERM" => "unknown")).to eq :none
      end

      it "lets that disclaimer win over anything else it claims" do
        expect(detect("TERM" => "dumb", "COLORTERM" => "truecolor")).to eq :none
        expect(detect("TERM" => "dumb", "WT_SESSION" => "abc")).to eq :none
      end

      it "guesses low when there is no signal at all" do
        expect(detect({})).to eq :none
        expect(detect("TERM" => "")).to eq :none
      end
    end

    it "never returns a level it doesn't recognize" do
      [
        {}, {"TERM" => "dumb"}, {"TERM" => "xterm"}, {"COLORTERM" => "truecolor"},
        {"FORCE_COLOR" => "2"}, {"WT_SESSION" => "1"}, {"TERM" => "xterm-256color"}
      ].each do |env|
        expect(described_class).to be_valid(detect(env))
      end
    end
  end

  describe ".valid?" do
    it "accepts every level" do
      described_class::ALL.each { |level| expect(described_class).to be_valid(level) }
    end

    it "rejects anything else" do
      expect(described_class).to_not be_valid(:ansi64)
      expect(described_class).to_not be_valid(nil)
    end
  end
end
