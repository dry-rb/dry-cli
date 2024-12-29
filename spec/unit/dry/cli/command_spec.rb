# frozen_string_literal: true

RSpec.describe "Command" do
  describe "#self.mutually_exclusive_options" do
    class MutuallyExclusiveOpts < Dry::CLI::Command
      mutually_exclusive_options [
        [:steps, {desc: "Number of versions to rollback"}],
        [:version, {desc: "The target version of the rollback (see `foo db version`)"}]
      ]

      def call(**); end
    end

    it "defines mutually exclusive options" do
      c = MutuallyExclusiveOpts.new

      opts = c.options
      expect(opts.size).to eq(2)
      expect(opts[0].name).to eq(:steps)
      expect(opts[0].conflicts_with).to eq([:version])
      expect(opts[1].name).to eq(:version)
      expect(opts[1].conflicts_with).to eq([:steps])
    end
  end
end
