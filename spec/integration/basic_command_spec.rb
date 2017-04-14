RSpec.describe "Basic command" do
  it "prints world" do
    output = `foo hello`
    expect(output).to match("world")
  end

  it "prints version" do
    output = `foo version`
    expect(output).to match("1.0.0 yay!")
  end

  it "fails for unknown command" do
    result = system("foo unknown")
    expect(result).to be(false)
  end
end
