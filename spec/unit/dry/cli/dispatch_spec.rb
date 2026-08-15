# frozen_string_literal: true

RSpec.describe Dry::CLI::Dispatch do
  let(:args) { {name: "web", url: "/u", skip_tests: true} }

  def callable(&definition)
    Class.new { define_method(:call, &definition) }.new.method(:call)
  end

  describe ".args_for" do
    context "when the callable declares a keyword splat" do
      it "passes everything through for `**opts`" do
        method = callable { |**opts| opts }

        expect(described_class.args_for(method, args)).to eq(args)
      end

      it "passes everything through for `name:, **`" do
        method = callable { |name:, **| name }

        expect(described_class.args_for(method, args)).to eq(args)
      end
    end

    context "when the callable declares no keywords at all" do
      # they read the params from a single positional Hash, which filtering would empty
      it "passes everything through for `*args`" do
        method = callable { |*positional| positional }

        expect(described_class.args_for(method, args)).to eq(args)
      end

      it "passes everything through for a block taking one positional" do
        block = proc { |params| params }

        expect(described_class.args_for(block, args)).to eq(args)
      end

      it "passes everything through for a block taking nothing" do
        block = proc { nil }

        expect(described_class.args_for(block, args)).to eq(args)
      end
    end

    context "when the callable declares keywords and no splat" do
      it "passes only the declared keywords" do
        method = callable { |name:, skip_tests: false| [name, skip_tests] }

        expect(described_class.args_for(method, args)).to eq(name: "web", skip_tests: true)
      end

      it "omits keywords that weren't parsed" do
        method = callable { |name:, missing: nil| [name, missing] }

        expect(described_class.args_for(method, args)).to eq(name: "web")
      end

      it "leaves a required keyword missing, so the call still raises" do
        method = callable { |absent:| absent }

        expect(described_class.args_for(method, args)).to eq({})
        # JRuby renders the keyword without the leading colon
        expect { method.call(**described_class.args_for(method, args)) }
          .to raise_error(ArgumentError, /missing keyword: :?absent/)
      end
    end

    it "lets a narrow signature accept params it doesn't declare" do
      method = callable { |name:| name }

      expect { method.call(**args) }.to raise_error(ArgumentError, /unknown keyword/)
      expect { method.call(**described_class.args_for(method, args)) }.not_to raise_error
    end
  end

  describe ".command_args_for" do
    it "filters against the command's #call" do
      command = Class.new(Dry::CLI::Command) do
        def call(name:); end
      end.new

      expect(described_class.command_args_for(command, args)).to eq(name: "web")
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

      expect(described_class.command_args_for(command, args)).to eq(args)
    end
  end
end
