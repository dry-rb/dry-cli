# frozen_string_literal: true

require "open3"
require "json"

RSpec.describe "Dry Types extension" do
  it "works with default values" do
    output, _, = Open3.capture3("with_dry_types info system")

    expect(JSON.parse(output.chomp)).to eq(
      {"lines" => 10, "sudo_mode" => false, "type" => "system"}
    )
  end

  it "casts values according to types" do
    output, _, = Open3.capture3("with_dry_types info system 15 --sudo_mode true")

    expect(JSON.parse(output.chomp)).to eq(
      {"args" => ["15"], "lines" => 15, "sudo_mode" => true, "type" => "system"}
    )
  end

  it "raises a standar Dry CLI error when casting fails" do
    _, stderr, = Open3.capture3("with_dry_types info system --sudo_mode not_false")
    expect(stderr).to eq("ERROR: \"with_dry_types info\" was called with arguments \"system --sudo_mode not_false\"\n")
  end
end
