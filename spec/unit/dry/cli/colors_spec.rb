# frozen_string_literal: true

RSpec.describe "Colors" do
  module Dummy
    module_function

    include Dry::CLI::Colors

    def only_bold
      bold("one")
    end

    def bold_and_black
      black(bold("two"))
    end
  end

  it "doesn't duplicate clean escape sequences" do
    only_bold = Dummy.only_bold
    expect(only_bold.end_with?("\e[0m")).to eq(true)
    expect(only_bold.end_with?("\e[0m\e[0m")).to eq(false)
    bold_and_black = Dummy.bold_and_black
    expect(bold_and_black.end_with?("\e[0m")).to eq(true)
    expect(bold_and_black.end_with?("\e[0m\e[0m")).to eq(false)
  end
end
