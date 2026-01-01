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
end
