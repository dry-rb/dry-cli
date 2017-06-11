RSpec.describe "Third-party gems" do
  it "allows to override basic commands" do
    output = `foo hello`
    expect(output).to eq("world\n")
  end

  it "allows to add a subcommand" do
    output = `foo generate webpack`
    expect(output).to eq("generated configuration\n")
  end

  it "allows to override a subcommand" do
    output = `foo generate action`
    expect(output).to eq("generated action\n")
  end
end
