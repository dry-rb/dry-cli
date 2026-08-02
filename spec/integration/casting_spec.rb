# frozen_string_literal: true

require "open3"
require "json"

RSpec.describe "arguments casting" do
  context "Dry Types support" do
    it "works with default values" do
      output, _, = Open3.capture3("with_casting info system")

      expect(JSON.parse(output.chomp)).to eq(
        {"lines" => 10, "sudo_mode" => false, "type" => "system"}
      )
    end

    it "casts values according to types" do
      output, _, = Open3.capture3("with_casting info system 15 --sudo_mode true")

      expect(JSON.parse(output.chomp)).to eq(
        {"args" => ["15"], "lines" => 15, "sudo_mode" => true, "type" => "system"}
      )
    end

    it "uses default from :default option over casting default" do
      output, _, = Open3.capture3("with_casting info system")

      expect(JSON.parse(output.chomp)).to eq(
        {"lines" => 10, "sudo_mode" => false, "type" => "system"}
      )
    end

    it "prints a detailed error when casting fails" do
      _, stderr, = Open3.capture3("with_casting info system --sudo_mode not_false")
      expect(stderr).to eq("ERROR when casting sudo_mode: not_false cannot be coerced to false.\n")
    end
  end

  context "simple lambda casting" do
    it "casts value with a simple lambda" do
      output, _ = Open3.capture3("with_casting info system --uid 16")

      expect(JSON.parse(output.chomp)).to eq(
        {"lines" => 10, "sudo_mode" => false, "type" => "system", "uid" => 16}
      )
    end
  end

  context "compatibility with :type" do
    it "with :array type casts every element" do
      output, _ = Open3.capture3("with_casting info system --flags foo,baz,hoozah")

      expect(JSON.parse(output.chomp)).to eq(
        {"lines" => 10, "sudo_mode" => false, "type" => "system", "flags" => ["oof", "zab", "hazooh"]}
      )
    end

    it "with :array type casts every element of an argument" do
      output, _ = Open3.capture3("with_casting tags foo baz")

      expect(JSON.parse(output.chomp)).to eq(
        {"tags" => ["FOO", "BAZ"], "args" => ["foo", "baz"]}
      )
    end

    it "with :array type leaves an omitted argument uncast" do
      output, _ = Open3.capture3("with_casting tags")

      expect(JSON.parse(output.chomp)).to eq({"tags" => []})
    end
  end
end
