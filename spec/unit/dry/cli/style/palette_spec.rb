# frozen_string_literal: true

RSpec.describe Dry::CLI::Style::Palette do
  describe "XTERM" do
    it "holds all 256 colors" do
      expect(described_class::XTERM.length).to eq 256
    end

    it "starts with the 16 ANSI colors" do
      expect(described_class::XTERM[0, 16]).to eq described_class::ANSI
    end

    it "lays the color cube out as xterm does" do
      # code = 16 + 36r + 6g + b, over the six intensities
      expect(described_class::XTERM[16]).to eq [0, 0, 0]
      expect(described_class::XTERM[16 + 1]).to eq [0, 0, 95]
      expect(described_class::XTERM[16 + 6]).to eq [0, 95, 0]
      expect(described_class::XTERM[16 + 36]).to eq [95, 0, 0]
      expect(described_class::XTERM[196]).to eq [255, 0, 0] # 16 + 36*5
      expect(described_class::XTERM[231]).to eq [255, 255, 255]
    end

    it "ends with the gray ramp" do
      expect(described_class::XTERM[232]).to eq [8, 8, 8]
      expect(described_class::XTERM[255]).to eq [238, 238, 238]
    end
  end

  describe ".nearest_xterm" do
    it "finds an exact match" do
      expect(described_class.nearest_xterm(255, 0, 0)).to eq 196
      expect(described_class.nearest_xterm(0, 255, 0)).to eq 46
      expect(described_class.nearest_xterm(0, 0, 255)).to eq 21
    end

    it "finds the closest match" do
      expect(described_class.nearest_xterm(254, 1, 1)).to eq 196
      expect(described_class.nearest_xterm(135, 175, 215)).to eq 110
    end

    it "uses the gray ramp for grays it fits better than the cube" do
      expect(described_class.nearest_xterm(88, 88, 88)).to eq 240
    end

    it "never returns a themeable color" do
      # Codes 0-15 are whatever the user has made them, so we stay out of that range
      256.times do |red|
        expect(described_class.nearest_xterm(red, red, red)).to be >= 16
      end
    end

    it "round trips every palette color above the themeable range" do
      (16..255).each do |code|
        expect(described_class.nearest_xterm(*described_class.rgb(code))).to eq code
      end
    end
  end

  describe ".nearest_ansi" do
    it "finds an exact match" do
      described_class::ANSI.each_with_index do |(red, green, blue), index|
        expect(described_class.nearest_ansi(red, green, blue)).to eq index
      end
    end

    it "picks bright colors for vivid ones" do
      expect(described_class.nearest_ansi(255, 0, 0)).to eq 9 # bright_red
      expect(described_class.nearest_ansi(0, 255, 255)).to eq 14 # bright_cyan
    end

    it "picks base colors for muted ones" do
      expect(described_class.nearest_ansi(120, 10, 10)).to eq 1 # red
      expect(described_class.nearest_ansi(10, 10, 120)).to eq 4 # blue
    end

    context "keeping hue" do
      it "matches a mid-tone against colors, not against the gray nearest it" do
        # #8b5cf6 sits closer to gray than to any purple the palette has
        expect(described_class.nearest_ansi(0x8b, 0x5c, 0xf6)).to eq 5 # magenta
      end

      it "still matches a gray against grays" do
        expect(described_class.nearest_ansi(148, 163, 184)).to eq 7 # white
        expect(described_class.nearest_ansi(250, 248, 245)).to eq 15 # bright_white
      end

      it "treats a near-black as black, however its channels lean" do
        expect(described_class.nearest_ansi(10, 10, 30)).to eq 0
        expect(described_class.nearest_ansi(30, 41, 59)).to eq 0
      end

      it "keeps the hue of a dark but colorful color" do
        expect(described_class.nearest_ansi(22, 101, 52)).to eq 2 # green
      end
    end
  end

  describe ".nearest_base_ansi" do
    it "never returns a bright color" do
      [[255, 0, 0], [0, 255, 0], [255, 255, 255], [128, 128, 128]].each do |rgb|
        expect(described_class.nearest_base_ansi(*rgb)).to be_between(0, 7)
      end
    end

    it "finds an exact match among the base colors" do
      described_class::ANSI[0, 8].each_with_index do |(red, green, blue), index|
        expect(described_class.nearest_base_ansi(red, green, blue)).to eq index
      end
    end

    it "maps bright colors onto their base" do
      expect(described_class.nearest_base_ansi(255, 0, 0)).to eq 1 # red
      expect(described_class.nearest_base_ansi(0, 255, 0)).to eq 2 # green
    end
  end

  describe ".rgb" do
    it "returns the components for a code" do
      expect(described_class.rgb(196)).to eq [255, 0, 0]
    end

    it "raises for a code outside the palette" do
      expect { described_class.rgb(256) }.to raise_error(IndexError)
    end
  end
end
