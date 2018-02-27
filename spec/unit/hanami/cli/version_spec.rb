RSpec.describe "Hanami::CLI::VERSION" do
  it "exposes version" do
    expect(Hanami::CLI::VERSION).to eq("0.1.1")
  end
end
