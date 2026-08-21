# frozen_string_literal: true

RSpec.describe Dry::CLI::Registry do
  # adding an option mutates the command class, so each example needs its own command
  def build_registry(command)
    Module.new do
      extend Dry::CLI::Registry

      register "alpha", command
    end
  end

  let(:command) do
    Class.new(Dry::CLI::Command) do
      option :existing, type: :flag, default: false

      def call(*); end
    end
  end

  let(:registry) { build_registry(command) }

  # Registers `hook` ("before"/"after") for "alpha", then runs that chain against `args`.
  def run_hook(hook, callback = nil, &blk)
    registry.public_send(hook, "alpha", callback, &blk)
    registry.get(["alpha"]).public_send(:"#{hook}_callbacks").run(command.new, **args)
  end

  describe ".command" do
    it "returns the registered command" do
      expect(registry.command("alpha")).to be(command)
    end

    it "returns the registered instance, when one was registered" do
      instance = command.new
      registry = build_registry(instance)

      expect(registry.command("alpha")).to be(instance)
    end

    it "raises error when the command can't be found" do
      expect { registry.command("pixel") }.to raise_error(
        Dry::CLI::UnknownCommandError,
        "unknown command: `pixel'"
      )
    end

    it "allows the command to be extended directly" do
      registry.command("alpha").option(:added, type: :flag)

      expect(command.options.map(&:name)).to include(:added)
    end
  end

  describe ".option" do
    it "adds the option to the command" do
      registry.option("alpha", :skip_tests, type: :flag, default: false, desc: "Skip tests")

      option = command.options.find { _1.name == :skip_tests }
      expect(option.type).to be(:flag)
      expect(option.default).to be(false)
      expect(option.desc).to eq("Skip tests")
    end

    it "keeps the command's own options" do
      registry.option("alpha", :skip_tests, type: :flag)

      expect(command.options.map(&:name)).to eq(%i[existing skip_tests])
    end

    it "adds the option to the class, when an instance was registered" do
      registry = build_registry(command.new)
      registry.option("alpha", :skip_tests, type: :flag)

      expect(command.options.map(&:name)).to include(:skip_tests)
    end

    it "raises error when the command can't be found" do
      expect { registry.option("pixel", :skip_tests) }.to raise_error(
        Dry::CLI::UnknownCommandError,
        "unknown command: `pixel'"
      )
    end

    context "when the same option is added more than once" do
      it "is a no-op when the settings match" do
        registry.option("alpha", :skip_tests, type: :flag, default: false, desc: "From one gem")
        registry.option("alpha", :skip_tests, type: :flag, default: false, desc: "From another")

        options = command.options.select { _1.name == :skip_tests }
        expect(options.count).to be(1)
        expect(options.first.desc).to eq("From one gem")
      end

      it "is a no-op when it matches an option the command already declares" do
        registry.option("alpha", :existing, type: :flag, default: false)

        expect(command.options.count { _1.name == :existing }).to be(1)
      end

      it "treats an omitted :required as the same as `required: false`" do
        registry.option("alpha", :skip_tests, type: :flag)

        expect { registry.option("alpha", :skip_tests, type: :flag, required: false) }
          .not_to raise_error
      end

      it "ignores a differing :cast, which can't be compared" do
        registry.option("alpha", :level, cast: ->(v) { v.to_i })

        expect { registry.option("alpha", :level, cast: ->(v) { v.to_s }) }.not_to raise_error
      end

      %i[type required values default].each do |setting|
        it "raises error when :#{setting} differs" do
          settings = {type: :string, required: false, values: %w[a b], default: "a"}
          registry.option("alpha", :level, settings)

          differing = settings.merge(
            setting => {type: :flag, required: true, values: %w[c d], default: "z"}[setting]
          )

          expect { registry.option("alpha", :level, differing) }.to raise_error(
            Dry::CLI::IncompatibleOptionError,
            "`level' is already declared for command `alpha' with a different #{setting}"
          )
        end
      end

      it "reports every setting that differs" do
        registry.option("alpha", :level, type: :string, default: "a")

        expect { registry.option("alpha", :level, type: :flag, default: "z") }.to raise_error(
          Dry::CLI::IncompatibleOptionError,
          "`level' is already declared for command `alpha' with a different type, default"
        )
      end
    end
  end

  %w[before after].each do |hook|
    describe ".#{hook}" do
      it "raises error when the command can't be found" do
        expect { registry.public_send(hook, "pixel") { puts "hello" } }.to raise_error(
          Dry::CLI::UnknownCommandError,
          "unknown command: `pixel'"
        )
      end

      context "when object is given" do
        it "raises error when it doesn't respond to #call" do
          callback = Object.new

          expect { registry.public_send(hook, "alpha", callback) }.to raise_error(
            Dry::CLI::InvalidCallbackError,
            "expected `#{callback.inspect}' to respond to `#call'"
          )
        end
      end

      context "when class is given" do
        it "raises error when #initialize arity is not equal to 0" do
          callback = Class.new do
            def initialize(foo); end
          end

          expect { registry.public_send(hook, "alpha", callback) }.to raise_error(
            Dry::CLI::InvalidCallbackError,
            "expected `#{callback.inspect}' to respond to `#initialize' with arity 0"
          )
        end
      end

      context "when the callback runs" do
        let(:args) { {name: "web", skip_tests: true} }

        it "passes only the declared params to a lambda" do
          received = nil
          run_hook(hook, ->(name:) { received = name })

          expect(received).to eq("web")
        end

        it "passes only the declared params to a proc" do
          received = nil
          run_hook(hook, proc { |name:| received = name })

          expect(received).to eq("web")
        end

        it "passes only the declared params to a block" do
          received = nil
          run_hook(hook) { |name:| received = name }

          expect(received).to eq("web")
        end

        it "passes only the declared params to an object" do
          received = nil
          callback = Class.new do
            define_method(:call) { |name:| received = name }
          end.new

          run_hook(hook, callback)

          expect(received).to eq("web")
        end

        it "passes every param to a lambda taking a single positional" do
          received = nil
          run_hook(hook, ->(params) { received = params })

          expect(received).to eq(args)
        end

        it "passes every param to a lambda declaring a keyword splat" do
          received = nil
          run_hook(hook, ->(name:, **rest) { received = [name, rest] })

          expect(received).to eq(["web", {skip_tests: true}])
        end
      end
    end
  end
end
