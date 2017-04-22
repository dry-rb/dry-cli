RSpec.describe "Basic command" do
  context "commands" do
    it "calls basic command" do
      output = `foo hello`
      expect(output).to match("world")
    end

    it "fails for unknown command" do
      result = system("foo unknown")
      expect(result).to be(false)
    end
  end

  context "subcommands" do
    it "calls subcommand" do
      output = `foo generate model`
      expect(output).to match("generated model")
    end

    it "fails for unknown subcommand" do
      result = system("foo generate unknown")
      expect(result).to be(false)
    end
  end

  context "third-party gems" do
    it "allows to override basic commands" do
      output = `foo version`
      expect(output).to match("1.0.0 yay!")
    end

    it "allows to add a subcommand" do
      output = `foo generate webpack`
      expect(output).to match("generated configuration")
    end

    it "allows to override a subcommand" do
      output = `foo generate action`
      expect(output).to match("generated action")
    end
  end
end
