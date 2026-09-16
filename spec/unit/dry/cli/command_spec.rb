# frozen_string_literal: true

RSpec.describe "Command" do
  describe "option definition" do
    class CommandWithDuplicateOpts < Dry::CLI::Command
      option :engine, desc: "1", values: %w[irb pry ripl]
      option :engine, desc: "2", values: %w[test1 test2 test3]
    end

    it "prevents duplicate options" do
      opts = CommandWithDuplicateOpts.options
      expect(opts.size).to eq(1)
      op = opts.first
      expect(op.name).to eq(:engine)
      expect(op.desc).to eq("2: (test1, test2, test3)")
    end
  end

  describe "long description definition" do
    class CommandWithLongDesc < Dry::CLI::Command
      desc "Short description"
      long_desc "A much longer description of what this command does"
    end

    it "stores the long description separately from the short one" do
      expect(CommandWithLongDesc.description).to eq("Short description")
      expect(CommandWithLongDesc.long_description).to eq(
        "A much longer description of what this command does"
      )
    end
  end

  describe "argument definition" do
    class CommandWithDuplicateArgs < Dry::CLI::Command
      argument :version, desc: "1"
      argument :version, desc: "2"
    end

    it "prevents duplicate arguments" do
      opts = CommandWithDuplicateArgs.arguments
      expect(opts.size).to eq(1)
      op = opts.first
      expect(op.name).to eq(:version)
      expect(op.desc).to eq("2")
    end
  end

  # Commands are given their streams before `#initialize` runs, so they have no `super` to call
  # rubocop:disable Lint/MissingSuper
  describe "construction" do
    let(:command_class) do
      Class.new(Dry::CLI::Command) do
        attr_reader :greeting

        def initialize(greeting: "Hello")
          @greeting = greeting
        end

        def call(**) = puts(greeting)
      end
    end

    it "gives a subclass its streams without them reaching #initialize" do
      out = StringIO.new

      command = command_class.new(stdout: out, greeting: "Howdy")

      expect(command.greeting).to eq "Howdy"
      command.call
      expect(out.string).to eq "Howdy\n"
    end

    it "makes the streams available inside #initialize" do
      out = StringIO.new

      Class.new(Dry::CLI::Command) {
        def initialize
          puts "Initialized"
        end
      }.new(stdout: out)

      expect(out.string).to eq "Initialized\n"
    end

    it "passes along everything else the subclass asks for" do
      command = Class.new(Dry::CLI::Command) do
        attr_reader :args, :block

        def initialize(*args, **kwargs, &block)
          @args = [args, kwargs]
          @block = block
        end
      end

      instance = command.new(1, 2, stdout: StringIO.new, dep: "dep") { :called }

      expect(instance.args).to eq [[1, 2], {dep: "dep"}]
      expect(instance.block.call).to be :called
    end

    it "rejects keywords the command does not accept" do
      command = Class.new(Dry::CLI::Command)

      expect { command.new(stdou: StringIO.new) }.to raise_error ArgumentError
    end

    describe "auto-initialized keywords" do
      it "names the keywords .new gives to #auto_initialize" do
        expect(Dry::CLI::Command.auto_initialize_keywords).to eq %i[stderr stdin stdout]
      end

      it "assigns a subclass's own keyword before #initialize runs" do
        command_class = Class.new(Dry::CLI::Command) do
          private def auto_initialize(fs: nil, **kwargs)
            super(**kwargs)
            @fs = fs
          end

          attr_reader :seen

          def initialize
            @seen = [stdout, @fs]
          end
        end

        out = StringIO.new
        command = command_class.new(stdout: out, fs: "fs")

        expect(command.seen[0].raw).to be out
        expect(command.seen[1]).to eq "fs"
      end

      it "keeps an auto-initialized keyword away from #initialize" do
        command_class = Class.new(Dry::CLI::Command) do
          private def auto_initialize(fs: nil, **kwargs)
            super(**kwargs)
            @fs = fs
          end

          attr_reader :kwargs

          def initialize(**kwargs)
            @kwargs = kwargs
          end
        end

        command = command_class.new(stdout: StringIO.new, fs: "fs", dep: "dep")

        expect(command.kwargs).to eq({dep: "dep"})
      end

      it "collects the keywords from every #auto_initialize in the hierarchy" do
        base = Class.new(Dry::CLI::Command) do
          private def auto_initialize(fs: nil, **kwargs)
            super(**kwargs)
            @fs = fs
          end
        end

        command_class = Class.new(base) do
          attr_reader :seen

          private def auto_initialize(system_call: nil, nested: false, **kwargs)
            super(**kwargs)
            @seen = [stdout, @fs, system_call, nested]
          end
        end

        out = StringIO.new
        command = command_class.new(stdout: out, fs: "fs", system_call: "call", nested: true)

        expect(command_class.auto_initialize_keywords)
          .to eq %i[stderr stdin stdout fs system_call nested]
        expect(command.seen[0].raw).to be out
        expect(command.seen[1..]).to eq ["fs", "call", true]
      end

      it "leaves a class that adds no keywords of its own with those of its superclass" do
        base = Class.new(Dry::CLI::Command) do
          private def auto_initialize(fs: nil, **kwargs)
            super(**kwargs)
            @fs = fs
          end
        end

        expect(Class.new(base).auto_initialize_keywords).to eq %i[stderr stdin stdout fs]
      end

      it "collects the keywords declared anywhere in the command's ancestry" do
        prepended = Module.new do
          def auto_initialize(from_prepend: nil, **kwargs)
            super(**kwargs)
            @from_prepend = from_prepend
          end
        end

        included = Module.new do
          def auto_initialize(from_include: nil, **kwargs)
            super(**kwargs)
            @from_include = from_include
          end
        end

        # Prepending puts the module ahead of the class, including puts it behind, so the class's
        # own `#auto_initialize` sits between the two
        command_class = Class.new(Dry::CLI::Command) do
          prepend prepended
          include included

          attr_reader :from_prepend, :from_include, :own

          private def auto_initialize(own: nil, **kwargs)
            super(**kwargs)
            @own = own
          end
        end

        command = command_class.new(
          stdout: StringIO.new, from_prepend: "prepend", from_include: "include", own: "own"
        )

        expect(command_class.auto_initialize_keywords)
          .to eq %i[stderr stdin stdout from_include own from_prepend]
        expect([command.from_prepend, command.from_include, command.own])
          .to eq %w[prepend include own]
      end
    end

    it "allows a subclass to catch and forward our stream keywords itself" do
      out = StringIO.new
      command = Class.new(Dry::CLI::Command) do
        def initialize(greeting: "Hello", **opts)
          super(**opts)
          @greeting = greeting
        end

        def call(**) = puts(@greeting)
      end

      command.new(stdout: out, greeting: "Howdy").call

      expect(out.string).to eq "Howdy\n"
    end
  end

  describe "#with_streams" do
    let(:command_class) do
      Class.new(Dry::CLI::Command) do
        def initialize(greeting: "Hello")
          @greeting = greeting
        end

        def call(**) = puts(@greeting)
      end
    end

    it "returns a copy writing to the given streams, leaving the original alone" do
      original_out = StringIO.new
      copy_out = StringIO.new
      command = command_class.new(stdout: original_out, greeting: "Howdy")

      copy = command.with_streams(stderr: StringIO.new, stdin: StringIO.new, stdout: copy_out)

      command.call
      copy.call
      copy.call
      expect(copy_out.string).to eq "Howdy\nHowdy\n"
      expect(original_out.string).to eq "Howdy\n"
    end
  end
  # rubocop:enable Lint/MissingSuper

  describe "writing output" do
    let(:command) do
      Class.new(Dry::CLI::Command) do
        def call(**)
          puts "to stdout"
          print "and more"
        end
      end
    end

    it "sends #puts and #print to the stream the command was given, not $stdout" do
      out = StringIO.new

      command.new(stdout: out).call

      expect(out.string).to eq "to stdout\nand more"
    end

    it "keeps them out of the command's public interface, as Kernel does" do
      expect(command.new).to_not respond_to(:puts)
      expect(command.new).to_not respond_to(:print)
    end
  end

  describe "streams" do
    let(:command) do
      Class.new(Dry::CLI::Command) do
        def call(**) = puts("written")
      end
    end

    it "writes everything to the stream it was given" do
      out = StringIO.new
      instance = command.new(stdout: out)

      instance.call
      instance.call

      expect(out.string).to eq "written\nwritten\n"
    end

    it "renders styled text for the stream it was given, not the Ruby default output" do
      out = StringIO.new
      styling = Class.new(Dry::CLI::Command) do
        def call(**) = puts(Dry::CLI::Style.bold.red["Uh oh"])
      end

      # A terminal for Ruby's own `$stdout`, so styling would be rendered if we went by
      # that instead of by the stream this command was given
      terminal = StringIO.new.tap { |io| def io.tty? = true }
      with_stdout(terminal) { styling.new(stdout: out).call }

      expect(out.string).to eq "Uh oh\n"
    end

    it "follows the Ruby default output when it changes between writes" do
      instance = command.new

      expect { instance.call }.to output("written\n").to_stdout
      expect { instance.call }.to output("written\n").to_stdout
    end

    it "writes to the Ruby default output when given none" do
      instance = command.new
      swapped = StringIO.new

      with_stdout(swapped) { instance.call }

      expect(swapped.string).to eq "written\n"
    end
  end
end
