RSpec.describe "Third-party gems" do
  it "allows to add a subcommand" do
    output = `foo generate webpack`
    expect(output).to eq("generate webpack\n")
  end

  it "allows to invoke a subcommand via an inherited subcomand aliases" do
    output = `foo g webpack`
    expect(output).to eq("generate webpack\n")
  end

  it "allows to override basic commands" do
    output = `foo hello`
    expect(output).to eq("hello from webpack\n")
  end

  it "allows to override a subcommand" do
    output = `foo sub command`
    expect(output).to eq("override from webpack\n")
  end
end
