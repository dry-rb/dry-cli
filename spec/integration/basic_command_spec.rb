RSpec.describe "Basic command" do
  it "prints world" do
    output = `foo hello`
    expect(output).to match("world")
  end

  it "fails for unknown command" do
    result = system("foo unknown")
    expect(result).to be(false)
  end
end
