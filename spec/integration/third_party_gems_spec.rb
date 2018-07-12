# frozen_string_literal: true

RSpec.describe "Third-party gems" do
  it "allows to add a subcommand" do
    output = `foo generate webpack`
    expect(output).to eq("generate webpack. Apps: []\n")
  end

  it "allows to invoke a subcommand via an inherited subcomand aliases" do
    output = `foo g webpack`
    expect(output).to eq("generate webpack. Apps: []\n")
  end

  it "allows to override basic commands" do
    output = `foo hello`
    expect(output).to eq("hello from webpack\n")
  end

  it "allows to override a subcommand" do
    output = `foo sub command`
    expect(output).to eq("override from webpack\n")
  end

  context "callbacks" do
    it "allows to add callbacks as a block" do
      expected = <<~OUTPUT
        before command callback Foo::Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>"."}
        before callback (class), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        before callback (object), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        dir: ., url: "https://hanamirb.test"
        after command callback Foo::Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>"."}
        after callback (class), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        after callback (object), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
      OUTPUT

      output = `foo callbacks . --url=https://hanamirb.test`
      expect(output).to eq(expected)
    end
  end

  it "allows to call array option" do
    output = `foo generate webpack --apps=test,api,admin`
    expect(output).to eq("generate webpack. Apps: [\"test\", \"api\", \"admin\"]\n")
  end
end
