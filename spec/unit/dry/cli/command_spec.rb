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
