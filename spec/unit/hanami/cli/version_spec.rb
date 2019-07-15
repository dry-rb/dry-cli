# frozen_string_literal: true

RSpec.describe "Hanami::CLI::VERSION" do
  it "exposes version" do
    expect(Hanami::CLI::VERSION).to eq("1.0.0.alpha1")
  end
end
