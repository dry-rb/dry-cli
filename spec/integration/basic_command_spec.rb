RSpec.describe "Basic command" do
  it "prints world" do
    output = `foo hello`
    expect(output).to match("world")
  end
end
