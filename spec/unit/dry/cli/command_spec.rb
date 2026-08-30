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
      expect(op.desc).to eq("2: (test1/test2/test3)")
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

    it "writes to the stream it was given" do
      out = StringIO.new

      command.new(stdout: out).call

      expect(out.string).to eq "written\n"
    end

    it "follows the program's own output when it was given none" do
      instance = command.new
      swapped = StringIO.new
      original = $stdout

      begin
        $stdout = swapped
        instance.call
      ensure
        $stdout = original
      end

      expect(swapped.string).to eq "written\n"
    end
  end
end
