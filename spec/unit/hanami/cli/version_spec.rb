RSpec.describe "Hanami::CLI::VERSION" do
  it "exposes version" do
    expect(Hanami::CLI::VERSION).to eq("0.3.0.beta1")
  end
end
