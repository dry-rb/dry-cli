# frozen_string_literal: true

RSpec.describe "Option" do
  describe "type casting" do
    it "supports :integer" do
      o = Dry::CLI::Option.new("test", {type: :integer})

      expect(o.type_cast("42")).to eq(42)
      expect(o.type_cast("4.2")).to eq(4)
    end

    it "supports :float" do
      o = Dry::CLI::Option.new("test", {type: :float})

      expect(o.type_cast("4.2")).to eq(4.2)
      expect(o.type_cast("42.42")).to eq(42.42)
    end

    it "supports :string" do
      o = Dry::CLI::Option.new("test", {type: :string})

      expect(o.type_cast("42")).to eq("42")
      expect(o.type_cast("42.42")).to eq("42.42")
      expect(o.type_cast("true")).to eq("true")
      expect(o.type_cast("this is a string")).to eq("this is a string")
    end

    it "returns the received value when no type is defined" do
      o = Dry::CLI::Option.new("test")

      expect(o.type_cast("42")).to eq("42")
      expect(o.type_cast("42.42")).to eq("42.42")
      expect(o.type_cast("true")).to eq("true")
      expect(o.type_cast("this is a string")).to eq("this is a string")
    end

    it "supports :boolean arguments" do
      o = Dry::CLI::Argument.new("test", {type: :boolean})

      expect(o.type_cast("true")).to eq(true)
      expect(o.type_cast("True")).to eq(true)
      expect(o.type_cast("TRUE")).to eq(true)
      expect(o.type_cast("t")).to eq(true)
      expect(o.type_cast("T")).to eq(true)
      expect(o.type_cast("1")).to eq(true)
      expect(o.type_cast("42")).to eq(true)
      expect(o.type_cast("42.42")).to eq(true)
      expect(o.type_cast("this is considered true")).to eq(true)

      expect(o.type_cast("false")).to eq(false)
      expect(o.type_cast("False")).to eq(false)
      expect(o.type_cast("FALSE")).to eq(false)
      expect(o.type_cast("off")).to eq(false)
      expect(o.type_cast("Off")).to eq(false)
      expect(o.type_cast("OFF")).to eq(false)
      expect(o.type_cast("f")).to eq(false)
      expect(o.type_cast("F")).to eq(false)
      expect(o.type_cast("0")).to eq(false)
    end

    it "considers :flag arguments as :boolean" do
      o = Dry::CLI::Argument.new("test", {type: :flag})

      expect(o.type_cast("true")).to eq(true)
      expect(o.type_cast("True")).to eq(true)
      expect(o.type_cast("TRUE")).to eq(true)
      expect(o.type_cast("t")).to eq(true)
      expect(o.type_cast("T")).to eq(true)
      expect(o.type_cast("1")).to eq(true)
      expect(o.type_cast("42")).to eq(true)
      expect(o.type_cast("42.42")).to eq(true)
      expect(o.type_cast("this is considered true")).to eq(true)

      expect(o.type_cast("false")).to eq(false)
      expect(o.type_cast("False")).to eq(false)
      expect(o.type_cast("FALSE")).to eq(false)
      expect(o.type_cast("off")).to eq(false)
      expect(o.type_cast("Off")).to eq(false)
      expect(o.type_cast("OFF")).to eq(false)
      expect(o.type_cast("f")).to eq(false)
      expect(o.type_cast("F")).to eq(false)
      expect(o.type_cast("0")).to eq(false)
    end
  end
end
