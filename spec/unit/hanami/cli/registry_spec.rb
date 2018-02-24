RSpec.describe Hanami::CLI::Registry do
  describe ".before" do
    it "raises error when command can't be found" do
      expect do
        Bar::CLI::Commands.before("pixel") { puts "hello" }
      end.to raise_error(Hanami::CLI::UnkwnownCommandError, "unknown command: `pixel'")
    end
  end

  describe ".after" do
    it "raises error when command can't be found" do
      expect do
        Bar::CLI::Commands.after("peta") { puts "hello" }
      end.to raise_error(Hanami::CLI::UnkwnownCommandError, "unknown command: `peta'")
    end
  end
end
