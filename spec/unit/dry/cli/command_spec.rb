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
end
