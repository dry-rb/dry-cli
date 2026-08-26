# frozen_string_literal: true

RSpec.describe Dry::CLI::StyleMixin do
  around do |example|
    Dry::CLI::Style.enabled = true
    example.run
    Dry::CLI::Style.enabled = nil
  end

  let(:subject_module) do
    Module.new do
      extend Dry::CLI::StyleMixin
    end
  end

  describe "#style" do
    it "returns a neutral style to chain from" do
      expect(subject_module.style.bold.red).to eq Dry::CLI::Style.bold.red
    end

    it "styles text directly" do
      expect(subject_module.style.bold.red("Boom")).to eq "\e[1;31mBoom\e[0m"
    end

    it "returns the given text unchanged" do
      expect(subject_module.style("Boom")).to eq "Boom"
    end
  end

  describe "#unstyle" do
    it "removes escape sequences" do
      expect(subject_module.unstyle("\e[1;31mBoom\e[0m")).to eq "Boom"
    end
  end

  describe "commands" do
    before do
      stub_const("Deploy", Class.new(Dry::CLI::Command) do
        error = style.bold.red

        define_method(:call) do |**|
          [error.call("Boom"), style.dim("quiet"), unstyle("\e[32mgreen\e[0m")]
        end
      end)
    end

    it "is available at the class level, for declaring styles" do
      expect(Deploy.style.bold.red).to eq Dry::CLI::Style.bold.red
    end

    it "is available at the instance level" do
      expect(Deploy.new.call).to eq ["\e[1;31mBoom\e[0m", "\e[2mquiet\e[0m", "green"]
    end
  end
end
