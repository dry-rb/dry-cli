# frozen_string_literal: true

RSpec.describe Dry::CLI::Stream do
  let(:terminal) { StringIO.new.tap { |io| def io.tty? = true } }
  let(:file) { StringIO.new }
  let(:styled) { "\e[1;31mBoom\e[0m" }

  describe ".for" do
    it "wraps the stream, so it can render what is written to it" do
      expect(described_class.for(file)).to be_an_instance_of(described_class)
      expect(described_class.for(terminal)).to be_an_instance_of(described_class)
    end

    it "leaves a stream it has already wrapped alone" do
      wrapped = described_class.for(file)

      expect(described_class.for(wrapped)).to be wrapped
    end
  end

  describe "#raw" do
    it "returns the stream it was made for" do
      expect(described_class.for(file).raw).to be file
    end

    it "writes without rendering, for escape sequences you wrote yourself" do
      described_class.for(file).raw.print "\e[2K\r"

      expect(file.string).to eq "\e[2K\r"
    end
  end

  describe "rendering styled text" do
    let(:styled) { Dry::CLI::Style.bold.red["Boom"] }

    around do |example|
      forced = ENV.delete("FORCE_COLOR")
      Dry::CLI::Style.enabled = nil
      Dry::CLI::Style.color_level = nil
      example.run
      ENV["FORCE_COLOR"] = forced if forced
      Dry::CLI::Style.enabled = nil
      Dry::CLI::Style.color_level = nil
    end

    it "renders for a terminal" do
      Dry::CLI::Style.color_level = :truecolor
      described_class.for(terminal).puts styled

      expect(terminal.string).to eq "\e[1;31mBoom\e[0m\n"
    end

    it "renders plain for a stream that is not one" do
      described_class.for(file).puts styled

      expect(file.string).to eq "Boom\n"
    end

    it "renders each stream for itself, from the one piece of text" do
      described_class.for(terminal).puts styled
      described_class.for(file).puts styled

      expect(terminal.string).to_not eq file.string
      expect(file.string).to eq "Boom\n"
    end

    it "doesn't go looking for styling in text that has none" do
      expect(Dry::CLI::Style).to_not receive(:unstyle)

      described_class.for(file).puts "a line of ordinary output"

      expect(file.string).to eq "a line of ordinary output\n"
    end

    it "renders text that was forced, even to a stream that is not a terminal" do
      Dry::CLI::Style.enabled = true
      Dry::CLI::Style.color_level = :truecolor

      described_class.for(file).puts styled

      expect(file.string).to eq "\e[1;31mBoom\e[0m\n"
    end
  end

  describe "writing" do
    subject(:stream) { described_class.for(file) }

    it "takes styling out of #puts" do
      stream.puts styled

      expect(file.string).to eq "Boom\n"
    end

    it "takes styling out of #print" do
      stream.print styled

      expect(file.string).to eq "Boom"
    end

    it "takes styling out of #write" do
      stream.write styled

      expect(file.string).to eq "Boom"
    end

    it "takes styling out of #<<, and still chains" do
      stream << styled << styled

      expect(file.string).to eq "BoomBoom"
    end

    it "takes styling out of #printf" do
      stream.printf("%s!", styled)

      expect(file.string).to eq "Boom!"
    end

    it "leaves unstyled text alone" do
      stream.puts "plain"

      expect(file.string).to eq "plain\n"
    end

    it "keeps #puts treating an array as one line each" do
      stream.puts [styled, "plain"]

      expect(file.string).to eq "Boom\nplain\n"
    end

    it "leaves anything that isn't a string to the stream, as #puts would" do
      stream.puts 42

      expect(file.string).to eq "42\n"
    end

    it "delegates everything else to the stream it wraps" do
      expect(stream.string).to eq ""
      expect(stream).to_not be_tty
    end
  end
end
