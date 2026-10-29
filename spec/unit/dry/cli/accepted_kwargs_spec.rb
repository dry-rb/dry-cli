# frozen_string_literal: true

RSpec.describe "Dry::CLI.accepted_kwargs" do
  let(:kwargs) { {name: "web", verbose: true} }

  it "returns the keyword args the callable can accept" do
    method = Class.new { def call(name:) = name }.new.method(:call)

    expect(Dry::CLI.accepted_kwargs(method, kwargs)).to eq(name: "web")
  end

  it "returns every keyword arg for a callable declaring a keyword splat" do
    block = proc { |**opts| opts }

    expect(Dry::CLI.accepted_kwargs(block, kwargs)).to eq(kwargs)
  end
end
