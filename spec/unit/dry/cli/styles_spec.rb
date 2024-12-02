# frozen_string_literal: true

RSpec.describe "Styles" do
  class Dummy
    include Dry::CLI::Styles

    def bold_and_black
      black(bold("two"))
    end
  end

  it "doesn't duplicate clean escape sequences" do
    bold_and_black = Dummy.new.bold_and_black
    expect(bold_and_black.end_with?("\e[0m")).to eq(true)
    expect(bold_and_black.end_with?("\e[0m\e[0m")).to eq(false)
  end
end
