# frozen_string_literal: true

RSpec.describe Dry::CLI::Dispatch do
  let(:args) { {name: "web", url: "/u", skip_tests: true} }

  def callable(&definition)
    Class.new { define_method(:call, &definition) }.new.method(:call)
  end

  describe ".accepted_kwargs" do
    context "when the callable declares a keyword splat" do
      it "passes everything through for `**opts`" do
        method = callable { |**opts| opts }

        expect(described_class.accepted_kwargs(method, args)).to eq(args)
      end

      it "passes everything through for `name:, **`" do
        method = callable { |name:, **| name }

        expect(described_class.accepted_kwargs(method, args)).to eq(args)
      end
    end

    context "when the callable takes a positional" do
      # `**` collapses to a single Hash for a callable declaring no keywords, and that Hash lands
      # in the positional, so filtering it would leave them with nothing to read
      it "passes everything through for `*args`" do
        method = callable { |*positional| positional }

        expect(described_class.accepted_kwargs(method, args)).to eq(args)
      end

      it "passes everything through for one required positional" do
        method = callable { |hash| hash }

        expect(described_class.accepted_kwargs(method, args)).to eq(args)
      end

      it "passes everything through for a block taking one positional" do
        block = proc { |hash| hash }

        expect(described_class.accepted_kwargs(block, args)).to eq(args)
      end
    end

    context "when the callable declares nothing at all" do
      it "passes nothing to a method taking no params" do
        method = callable { nil }

        expect(described_class.accepted_kwargs(method, args)).to eq({})
      end

      it "passes nothing to a block taking nothing" do
        block = proc { nil }

        expect(described_class.accepted_kwargs(block, args)).to eq({})
      end
    end

    context "when the callable declares keywords and no splat" do
      it "passes only the declared keywords" do
        method = callable { |name:, skip_tests: false| [name, skip_tests] }

        expect(described_class.accepted_kwargs(method, args)).to eq(name: "web", skip_tests: true)
      end

      it "omits keywords that weren't parsed" do
        method = callable { |name:, missing: nil| [name, missing] }

        expect(described_class.accepted_kwargs(method, args)).to eq(name: "web")
      end

      it "leaves a required keyword missing, so the call still raises" do
        method = callable { |absent:| absent }

        expect(described_class.accepted_kwargs(method, args)).to eq({})
        # JRuby renders the keyword without the leading colon
        expect { method.call(**described_class.accepted_kwargs(method, args)) }
          .to raise_error(ArgumentError, /missing keyword: :?absent/)
      end
    end

    it "lets a narrow signature accept args it doesn't declare" do
      method = callable { |name:| name }

      expect { method.call(**args) }.to raise_error(ArgumentError, /unknown keyword/)
      expect { method.call(**described_class.accepted_kwargs(method, args)) }.not_to raise_error
    end

    it "lets a signature declaring no params be called at all" do
      method = callable { nil }

      expect { method.call(**args) }.to raise_error(ArgumentError, /wrong number of arguments/)
      expect { method.call(**described_class.accepted_kwargs(method, args)) }.not_to raise_error
    end
  end

  describe ".command_accepted_kwargs" do
    it "filters against the command's #call" do
      command = Class.new(Dry::CLI::Command) do
        def call(name:); end
      end.new

      expect(described_class.command_accepted_kwargs(command, args)).to eq(name: "web")
    end

    it "passes nothing to a command declaring no params" do
      command = Class.new(Dry::CLI::Command) do
        def call; end
      end.new

      expect(described_class.command_accepted_kwargs(command, args)).to eq({})
    end

    it "passes everything through when #call has no inspectable signature" do
      command = Class.new(Dry::CLI::Command) do
        def respond_to_missing?(name, include_private = false)
          name == :call || super
        end

        def method_missing(name, *rest)
          name == :call ? nil : super
        end
      end.new

      expect(described_class.command_accepted_kwargs(command, args)).to eq(args)
    end
  end
end
