# frozen_string_literal: true

RSpec.describe Dry::CLI::Style do
  around do |example|
    described_class.enabled = true
    example.run
    described_class.enabled = nil
  end

  describe "building styles" do
    it "builds a style from the class" do
      expect(described_class.red).to eq described_class.new([31])
    end

    it "chains styles" do
      expect(described_class.bold.red.on_white).to eq described_class.new([1, 31, 47])
    end

    it "returns a new style for each step, leaving the receiver untouched" do
      bold = described_class.bold

      expect(bold.red).to_not eq bold
      expect(bold).to eq described_class.new([1])
    end

    it "is frozen" do
      expect(described_class.bold).to be_frozen
    end

    it "supports every style name" do
      described_class::CODES.each do |name, code|
        expect(described_class.public_send(name)).to eq described_class.new([code])
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

  describe "styling text directly" do
    it "styles the text when given as an argument" do
      expect(described_class.bold.red("Boom")).to eq "\e[1;31mBoom\e[0m"
    end

    it "returns a style when given no argument" do
      expect(described_class.bold.red).to be_an_instance_of(described_class)
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

    it "removes nested escape sequences" do
      expect(described_class.unstyle(described_class.bold.call("a#{described_class.red.call("b")}c")))
        .to eq "abc"
    end

    it "leaves unstyled text alone" do
      expect(described_class.unstyle("Boom")).to eq "Boom"
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
    end
  end

  describe "#inspect" do
    it "shows the style names" do
      expect(described_class.bold.red.inspect).to eq "#<Dry::CLI::Style bold.red>"
    end
  end

  def with_env(vars)
    original = ENV.to_hash
    ENV.update(vars)
    yield
  ensure
    ENV.replace(original)
  end
end
