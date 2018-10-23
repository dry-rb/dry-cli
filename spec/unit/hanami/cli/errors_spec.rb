RSpec.describe Hanami::CLI do
  describe "UnkwnownCommandError" do
    it "shows deprecation message" do
      expect do
        Hanami::CLI::UnkwnownCommandError.new(:foo)
      end.to output(include("UnkwnownCommandError is deprecated, please use UnknownCommandError")).to_stderr
    end
  end
end
