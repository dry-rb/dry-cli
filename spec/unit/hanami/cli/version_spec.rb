RSpec.describe "Hanami::CLI::VERSION" do
  it "exposes version" do
    expect(Hanami::CLI::VERSION).to eq("0.2.0.rc2")
  end
end
