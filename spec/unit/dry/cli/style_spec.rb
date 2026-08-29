# frozen_string_literal: true

RSpec.describe Dry::CLI::Style do
  around do |example|
    described_class.enabled = true
    described_class.color_level = :truecolor
    example.run
    described_class.enabled = nil
    described_class.color_level = nil
  end

  describe "building styles" do
    it "builds a style from the class" do
      expect(described_class.red).to eq described_class.new.red
    end

    it "chains styles" do
      expect(described_class.bold.red.on_white.codes).to eq [1, 31, 47]
    end

    it "returns a new style for each step, leaving the receiver untouched" do
      bold = described_class.bold

      expect(bold.red).to_not eq bold
      expect(bold.codes).to eq [1]
    end

    it "is frozen" do
      expect(described_class.bold).to be_frozen
    end

    it "supports every attribute" do
      described_class::ATTRIBUTES.each do |name, code|
        expect(described_class.public_send(name).codes).to eq [code]
      end
    end

    it "supports every color, in both layers and both intensities" do
      described_class::COLORS.each do |name, index|
        expect(described_class.public_send(name).codes).to eq [30 + index]
        expect(described_class.public_send(:"bright_#{name}").codes).to eq [90 + index]
        expect(described_class.public_send(:"on_#{name}").codes).to eq [40 + index]
        expect(described_class.public_send(:"on_bright_#{name}").codes).to eq [100 + index]
      end
    end
  end

  describe "#call" do
    it "wraps the text in a single escape sequence" do
      expect(described_class.bold.red.call("Boom")).to eq "\e[1;31mBoom\e[0m"
    end

    it "is aliased as #[]" do
      expect(described_class.red["Boom"]).to eq "\e[31mBoom\e[0m"
    end

    it "returns a String" do
      expect(described_class.red.call("Boom")).to be_an_instance_of(String)
    end

    it "coerces the text" do
      expect(described_class.red.call(42)).to eq "\e[31m42\e[0m"
    end

    it "can be applied repeatedly" do
      error = described_class.bold.red

      expect(error.call("Boom")).to eq "\e[1;31mBoom\e[0m"
      expect(error.call("Bang")).to eq "\e[1;31mBang\e[0m"
    end
  end

  describe "building a style" do
    it "returns a style, never styled text" do
      expect(described_class.bold.red).to be_an_instance_of(described_class)
    end

    it "does not take the text" do
      expect { described_class.bold.red("Boom") }.to raise_error(ArgumentError)
    end
  end

  describe "nesting" do
    it "reopens the outer style after a nested reset" do
      inner = described_class.red.call("world")

      expect(described_class.bold.call("hello #{inner} again"))
        .to eq "\e[1mhello \e[31mworld\e[0m\e[1m again\e[0m"
    end

    it "reopens after every nested reset" do
      inner = described_class.red.call("b")

      expect(described_class.bold.call("a#{inner}c#{inner}d"))
        .to eq "\e[1ma\e[31mb\e[0m\e[1mc\e[31mb\e[0m\e[1md\e[0m"
    end
  end

  describe "the neutral style" do
    it "returns the text unchanged" do
      expect(described_class.new.call("Boom")).to eq "Boom"
    end

    it "preserves nested styling" do
      expect(described_class.new.call("\e[31mBoom\e[0m")).to eq "\e[31mBoom\e[0m"
    end
  end

  describe "#to_proc" do
    it "can be passed as a block" do
      expect(%w[a b].map(&described_class.red)).to eq ["\e[31ma\e[0m", "\e[31mb\e[0m"]
    end
  end

  describe ".unstyle" do
    it "removes escape sequences" do
      expect(described_class.unstyle("\e[1;31mBoom\e[0m")).to eq "Boom"
    end

    it "removes 24-bit escape sequences" do
      expect(described_class.unstyle(described_class.rgb(255, 0, 0).call("Boom"))).to eq "Boom"
    end

    it "removes nested escape sequences" do
      nested = described_class.bold.call("a#{described_class.red.call("b")}c")

      expect(described_class.unstyle(nested)).to eq "abc"
    end

    it "leaves unstyled text alone" do
      expect(described_class.unstyle("Boom")).to eq "Boom"
    end
  end

  describe "#rgb" do
    it "renders 24-bit color" do
      expect(described_class.rgb(255, 128, 0).call("Boom")).to eq "\e[38;2;255;128;0mBoom\e[0m"
    end

    it "renders 24-bit background color" do
      expect(described_class.on_rgb(255, 128, 0).call("Boom")).to eq "\e[48;2;255;128;0mBoom\e[0m"
    end

    it "chains with other styles" do
      expect(described_class.bold.rgb(255, 0, 0).on_rgb(0, 0, 0).codes)
        .to eq [1, 38, 2, 255, 0, 0, 48, 2, 0, 0, 0]
    end

    it "rejects components outside 0-255" do
      expect { described_class.rgb(256, 0, 0) }.to raise_error(Dry::CLI::InvalidColorError)
      expect { described_class.rgb(-1, 0, 0) }.to raise_error(Dry::CLI::InvalidColorError)
    end

    it "rejects non-integer components" do
      expect { described_class.rgb("255", 0, 0) }.to raise_error(Dry::CLI::InvalidColorError)
      expect { described_class.rgb(nil, 0, 0) }.to raise_error(Dry::CLI::InvalidColorError)
    end
  end

  describe "#hex" do
    it "renders 24-bit color" do
      expect(described_class.hex("#ff8000").call("Boom")).to eq "\e[38;2;255;128;0mBoom\e[0m"
    end

    it "renders 24-bit background color" do
      expect(described_class.on_hex("#ff8000").call("Boom")).to eq "\e[48;2;255;128;0mBoom\e[0m"
    end

    it "accepts a value without the leading hash" do
      expect(described_class.hex("ff8000")).to eq described_class.rgb(255, 128, 0)
    end

    it "expands three digit values" do
      expect(described_class.hex("#f80")).to eq described_class.rgb(255, 136, 0)
    end

    it "is case insensitive" do
      expect(described_class.hex("#FF8000")).to eq described_class.hex("#ff8000")
    end

    it "rejects values that aren't hex colors" do
      ["#ff", "#ffff", "#gggggg", "", "red", nil].each do |value|
        expect { described_class.hex(value) }.to raise_error(Dry::CLI::InvalidColorError)
      end
    end
  end

  describe "#ansi256" do
    it "renders a palette color" do
      expect(described_class.ansi256(196).call("Boom")).to eq "\e[38;5;196mBoom\e[0m"
    end

    it "renders a palette background color" do
      expect(described_class.on_ansi256(235).call("Boom")).to eq "\e[48;5;235mBoom\e[0m"
    end

    it "rejects codes outside 0-255" do
      expect { described_class.ansi256(256) }.to raise_error(Dry::CLI::InvalidColorError)
      expect { described_class.ansi256(-1) }.to raise_error(Dry::CLI::InvalidColorError)
    end

    it "rejects non-integer codes" do
      expect { described_class.ansi256("196") }.to raise_error(Dry::CLI::InvalidColorError)
    end
  end

  describe "degrading color" do
    def render(style, level)
      described_class.color_level = level
      style.call("Boom")
    end

    context "a 24-bit color" do
      let(:style) { described_class.bold.rgb(255, 0, 0) }

      it "renders in full at :truecolor" do
        expect(render(style, :truecolor)).to eq "\e[1;38;2;255;0;0mBoom\e[0m"
      end

      it "picks the closest palette color at :ansi256" do
        expect(render(style, :ansi256)).to eq "\e[1;38;5;196mBoom\e[0m"
      end

      it "picks the closest of the 16 ANSI colors at :ansi16" do
        expect(render(style, :ansi16)).to eq "\e[1;91mBoom\e[0m"
      end

      it "picks the closest of the 8 ANSI colors at :ansi8" do
        expect(render(style, :ansi8)).to eq "\e[1;31mBoom\e[0m"
      end

      it "drops the color but keeps the attributes at :none" do
        expect(render(style, :none)).to eq "\e[1mBoom\e[0m"
      end
    end

    context "a background color" do
      let(:style) { described_class.on_rgb(0, 0, 255) }

      it "degrades on the background layer" do
        expect(render(style, :ansi256)).to eq "\e[48;5;21mBoom\e[0m"
        expect(render(style, :ansi16)).to eq "\e[104mBoom\e[0m"
        expect(render(style, :ansi8)).to eq "\e[44mBoom\e[0m"
      end
    end

    context "a palette color" do
      let(:style) { described_class.ansi256(196) }

      it "renders unchanged at :truecolor, which understands palette escapes" do
        expect(render(style, :truecolor)).to eq "\e[38;5;196mBoom\e[0m"
      end

      it "renders unchanged at :ansi256" do
        expect(render(style, :ansi256)).to eq "\e[38;5;196mBoom\e[0m"
      end

      it "picks the closest of the 16 ANSI colors at :ansi16" do
        expect(render(style, :ansi16)).to eq "\e[91mBoom\e[0m"
      end

      it "picks the closest of the 8 ANSI colors at :ansi8" do
        expect(render(style, :ansi8)).to eq "\e[31mBoom\e[0m"
      end

      it "drops the color at :none" do
        expect(render(style, :none)).to eq "Boom"
      end
    end

    context "a named color" do
      it "is untouched from :ansi16 upward" do
        %i[truecolor ansi256 ansi16].each do |level|
          expect(render(described_class.red, level)).to eq "\e[31mBoom\e[0m"
          expect(render(described_class.bright_red, level)).to eq "\e[91mBoom\e[0m"
        end
      end

      it "folds a bright color onto the color it brightens at :ansi8" do
        expect(render(described_class.bright_red, :ansi8)).to eq "\e[31mBoom\e[0m"
        expect(render(described_class.bright_black, :ansi8)).to eq "\e[30mBoom\e[0m"
        expect(render(described_class.on_bright_white, :ansi8)).to eq "\e[47mBoom\e[0m"
      end

      it "drops the color at :none" do
        expect(render(described_class.red, :none)).to eq "Boom"
      end
    end

    it "renders the same style differently as the level changes" do
      error = described_class.rgb(255, 0, 0)

      expect(render(error, :truecolor)).to_not eq render(error, :ansi256)
    end
  end

  describe ".color_level" do
    it "can be pinned" do
      described_class.color_level = :ansi256

      expect(described_class.color_level).to eq :ansi256
    end

    it "rejects unknown levels" do
      expect { described_class.color_level = :ansi64 }
        .to raise_error(ArgumentError, /unknown color level :ansi64/)
    end

    it "detects from the environment when unpinned" do
      described_class.color_level = nil

      with_env("COLORTERM" => "truecolor") do
        expect(described_class.color_level).to eq :truecolor
      end
    end

    it "is :none when styling is disabled" do
      described_class.enabled = false

      expect(described_class.color_level).to eq :none
    end
  end

  describe "enabling and disabling" do
    it "returns the text unchanged when disabled" do
      described_class.enabled = false

      expect(described_class.bold.red.call("Boom")).to eq "Boom"
    end

    it "strips existing styling when disabled" do
      styled = described_class.red.call("Boom")
      described_class.enabled = false

      expect(described_class.bold.call(styled)).to eq "Boom"
      expect(described_class.new.call(styled)).to eq "Boom"
    end

    context "deciding automatically" do
      before { described_class.enabled = nil }

      it "is disabled when not writing to a terminal" do
        expect($stdout).to receive(:tty?).and_return(false)

        expect(described_class).to_not be_enabled
      end

      it "is enabled when writing to a terminal" do
        expect($stdout).to receive(:tty?).and_return(true)

        expect(described_class).to be_enabled
      end

      it "is disabled when NO_COLOR is set" do
        allow($stdout).to receive(:tty?).and_return(true)

        with_env("NO_COLOR" => "1") do
          expect(described_class).to_not be_enabled
        end
      end

      it "is enabled when NO_COLOR is empty" do
        allow($stdout).to receive(:tty?).and_return(true)

        with_env("NO_COLOR" => "") do
          expect(described_class).to be_enabled
        end
      end

      it "is enabled when FORCE_COLOR is set, terminal or not" do
        allow($stdout).to receive(:tty?).and_return(false)

        with_env("FORCE_COLOR" => "1") do
          expect(described_class).to be_enabled
        end
      end

      it "is disabled when FORCE_COLOR is set to 0" do
        allow($stdout).to receive(:tty?).and_return(true)

        with_env("FORCE_COLOR" => "0") do
          expect(described_class).to_not be_enabled
        end
      end

      it "lets NO_COLOR win over FORCE_COLOR" do
        allow($stdout).to receive(:tty?).and_return(true)

        with_env("NO_COLOR" => "1", "FORCE_COLOR" => "3") do
          expect(described_class).to_not be_enabled
        end
      end
    end
  end

  describe "#inspect" do
    it "shows the style names" do
      expect(described_class.bold.red.inspect).to eq "#<Dry::CLI::Style bold.red>"
    end

    it "shows background colors with their prefix" do
      expect(described_class.on_bright_blue.inspect).to eq "#<Dry::CLI::Style on_bright_blue>"
    end

    it "shows color values" do
      expect(described_class.rgb(255, 0, 0).inspect).to eq "#<Dry::CLI::Style rgb(255, 0, 0)>"
      expect(described_class.on_ansi256(196).inspect).to eq "#<Dry::CLI::Style on_ansi256(196)>"
    end

    it "shows a neutral style" do
      expect(described_class.new.inspect).to eq "#<Dry::CLI::Style>"
    end
  end

  describe "equality" do
    it "is equal to a style with the same steps" do
      expect(described_class.bold.red).to eq described_class.bold.red
      expect(described_class.bold.red).to eql described_class.bold.red
      expect(described_class.bold.red.hash).to eq described_class.bold.red.hash
    end

    it "is not equal to a style with the same color on another layer" do
      expect(described_class.rgb(255, 0, 0)).to_not eq described_class.on_rgb(255, 0, 0)
    end

    it "is not equal to a style built a different way" do
      expect(described_class.red).to_not eq described_class.rgb(128, 0, 0)
    end

    it "distinguishes the order of steps" do
      expect(described_class.red.blue).to_not eq described_class.blue.red
    end
  end
end
