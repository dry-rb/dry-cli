# frozen_string_literal: true

RSpec.describe Dry::CLI::Style::Formatter do
  around do |example|
    Dry::CLI::Style.enabled = true
    Dry::CLI::Style.color_level = :truecolor
    example.run
    Dry::CLI::Style.enabled = nil
    Dry::CLI::Style.color_level = nil
  end

  let(:red) { Dry::CLI::Style.red }
  let(:bold) { Dry::CLI::Style.bold }
  let(:text_class) { Dry::CLI::Style::Text }

  def format_text(input, args)
    described_class.call(input, args)
  end

  describe "array arguments" do
    it "applies one argument list across parts in order" do
      styled = red["a %s"] + " and %s"
      result = format_text(styled, ["x", "y"])

      expect(result.parts).to eq [[red, "a x"], [nil, " and y"]]
      expect(result.render(:truecolor)).to eq "\e[31ma x\e[0m and y"
    end

    it "formats nested text and keeps it nested" do
      styled = red[bold["%s"]] + " %s"
      result = format_text(styled, ["x", "y"])

      expect(result.parts).to eq [[red, text_class.new([[bold, "x"]])], [nil, " y"]]
    end

    it "does not reconsume an argument when a replacement looks like a directive" do
      styled = red["%s"] + " " + red["%s"]

      expect(format_text(styled, ["%s", "x"]).plain).to eq "%s x"
    end

    it "does not consume an argument for an escaped percent" do
      styled = red["100%%"] + " %s"

      expect(format_text(styled, ["x"]).plain).to eq "100% x"
    end

    it "consumes width and precision arguments" do
      expect(format_text(red["%*d"], [5, 42]).plain).to eq "   42"
      expect(format_text(red["%.*f"], [2, 1.5]).plain).to eq "1.50"
    end

    it "supports positional references" do
      expect(format_text(red["%2$s %1$s"], %w[a b]).plain).to eq "b a"
    end

    it "leaves text with no directives alone" do
      expect(format_text(red["hello"], []).parts).to eq [[red, "hello"]]
      expect(format_text(red["hello"], ["extra"]).parts).to eq [[red, "hello"]]
    end

    it "ignores surplus arguments" do
      expect(format_text(red["%s"], %w[x y z]).plain).to eq "x"
    end

    it "coerces parts that are not strings" do
      styled = text_class.new([[nil, 5]]) + " %s"

      expect(format_text(styled, ["x"]).plain).to eq "5 x"
    end
  end

  describe "a single argument" do
    it "treats nil as one argument" do
      expect(format_text(red["%s"], nil).plain).to eq ""
    end
  end

  describe "an argument that responds to #to_ary" do
    it "splats the converted array into the argument list" do
      arg = double(:arg, to_ary: ["x", "y"])

      expect(format_text(red["%s %s"], arg).plain).to eq "x y"
    end

    it "treats a nil conversion as one argument" do
      arg = double(:arg, to_ary: nil)

      expect(format_text(red["%s"], arg).plain).to eq arg.to_s
    end

    it "raises when the conversion is not an array" do
      arg = double(:arg, to_ary: 42)

      expect { format_text(red["%s"], arg) }
        .to raise_error(TypeError, /to_ary gives Integer/)
    end

    it "takes precedence over a hash conversion" do
      arg = double(:arg, to_ary: ["x"], to_hash: {a: 1})

      expect(format_text(red["%s"], arg).plain).to eq "x"
      expect { format_text(red["%{a}"], arg) }
        .to raise_error(ArgumentError, /one hash required/)
    end
  end

  describe "formatting errors" do
    it "raises when there are not enough arguments" do
      expect { format_text(red["%s %s"], ["x"]) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "raises for an incomplete directive" do
      expect { format_text(red["100%"], ["x"]) }
        .to raise_error(ArgumentError, /incomplete format specifier/)
    end

    it "raises when a named directive receives an array" do
      expect { format_text(red["%{x}"], ["x"]) }
        .to raise_error(ArgumentError, /one hash required/)
    end

    it "raises when numbered and unnumbered directives are mixed" do
      styled = red["%2$s"] + "%s"

      expect { format_text(styled, %w[a b]) }
        .to raise_error(ArgumentError, /mixed with/)
    end
  end

  describe "hash arguments" do
    it "applies named arguments across parts" do
      styled = red["a %{x}"] + " %{y} %<x>s"

      expect(format_text(styled, {x: 1, y: 2}).plain).to eq "a 1 2 1"
    end

    it "formats a positional directive with the hash itself" do
      expect(format_text(red["%s"], {a: 1}).plain).to eq({a: 1}.to_s)
    end

    it "coerces a non-string part with a hash argument" do
      expect(format_text(text_class.new([[nil, 5]]), {a: 1}).plain).to eq "5"
    end

    it "formats nested text with named arguments and keeps it nested" do
      result = format_text(red[bold["%{a}"]], {a: 1})

      expect(result.parts).to eq [[red, text_class.new([[bold, "1"]])]]
    end

    it "leaves text with no directives alone with a hash argument" do
      expect(format_text(red["hello"], {a: 1}).plain).to eq "hello"
    end

    it "raises for a missing key" do
      expect { format_text(red["%{x}"], {y: 1}) }
        .to raise_error(KeyError, /key\{x\} not found/)
    end

    it "accepts an object that converts to a hash" do
      arg = double(:arg, to_hash: {a: 1})

      expect(format_text(red["%{a}"], arg).plain).to eq "1"
    end

    it "treats an object whose hash conversion is nil as one argument" do
      arg = double(:arg, to_hash: nil)

      expect(format_text(red["%s"], arg).plain).to eq arg.to_s
    end

    it "raises for a second positional directive across parts" do
      horizontal = text_class.new([[nil, "%s"], [nil, "%s"]])

      expect { format_text(horizontal, {a: 1}) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "treats the hash as one positional argument when a named reference is escaped" do
      expect { format_text(red["%%{a} %s %s"], {a: 1}) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "treats the hash as one positional argument when an angle bracket reference is escaped" do
      expect { format_text(red["%%<a>s %s %s"], {a: 1}) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "treats the hash as one positional argument after an even run of percents" do
      expect { format_text(red["%%%%{a} %s %s"], {a: 1}) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "recognizes a named reference after an odd run of percents" do
      expect(format_text(red["%%%{a}"], {a: 1}).plain).to eq "%1"
    end

    it "raises for a second positional directive with a to_hash object" do
      arg = double(:arg, to_hash: {a: 1})
      horizontal = text_class.new([[nil, "%s"], [nil, "%s"]])

      expect { format_text(horizontal, arg) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "raises for a second positional directive with a nil-returning to_hash object" do
      arg = double(:arg, to_hash: nil)
      horizontal = text_class.new([[nil, "%s"], [nil, "%s"]])

      expect { format_text(horizontal, arg) }
        .to raise_error(ArgumentError, /too few arguments/)
    end

    it "raises when named and positional directives are mixed across parts" do
      mix = text_class.new([[nil, "%{a} "], [nil, "%s"]])

      expect { format_text(mix, {a: 1}) }
        .to raise_error(ArgumentError, /mixed with/)
    end
  end

  describe "the returned text" do
    it "is styled text" do
      expect(format_text(red["%s"], ["x"])).to be_an_instance_of(text_class)
    end

    it "keeps the style of each part" do
      styled = red["a %s"] + " plain " + bold["%s"]
      result = format_text(styled, ["x", "y"])

      expect(result.parts).to eq [[red, "a x"], [nil, " plain "], [bold, "y"]]
    end

    it "does not bake nested styles into formatted text" do
      result = format_text(red[bold["%{a}"]], {a: 1})

      expect(result.parts).to eq [[red, text_class.new([[bold, "1"]])]]
      expect(result.plain).to eq "1"
      expect(result.render(nil)).to eq "1"
      expect(result.length).to eq 1
    end
  end

  describe "its inputs" do
    it "does not mutate the text or its arguments" do
      styled = red["a %s"] + " and %s"
      parts = styled.parts.dup
      args = ["x", "y"].freeze

      format_text(styled, args)

      expect(styled.parts).to eq parts
      expect(args).to eq ["x", "y"]
    end
  end

  describe "warnings" do
    it "doesn't produce warnings" do
      expect { format_text(red["a %s"] + " and %s", ["x", "y"]) }.to_not output.to_stderr
    end
  end
end
