# frozen_string_literal: true

RSpec.describe "Option" do
  describe "#conflicts_with?" do
    it "returns if the option/argument conflicts with the option/argument passed as the argument" do
      opt = Dry::CLI::Option.new(:opt, {conflicts_with: %i[arg]})
      arg = Dry::CLI::Argument.new(:arg, {conflicts_with: %i[a b]})
      without_conflicts = Dry::CLI::Argument.new(:arg2)

      expect(opt.conflicts_with?(:arg)).to eq(true)
      expect(opt.conflicts_with?(:a)).to eq(false)
      expect(arg.conflicts_with?(:a)).to eq(true)
      expect(arg.conflicts_with?(:b)).to eq(true)
      expect(arg.conflicts_with?(:opt)).to eq(false)
      expect(without_conflicts.conflicts_with?(:opt)).to eq(false)
      expect(without_conflicts.conflicts_with?(:arg)).to eq(false)
      expect(without_conflicts.conflicts_with?(:a)).to eq(false)
      expect(without_conflicts.conflicts_with?(:b)).to eq(false)
    end
  end
end
