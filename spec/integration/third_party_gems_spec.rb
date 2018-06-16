RSpec.describe "Third-party gems" do
  it "allows to add a subcommand" do
    output = `foo generate webpack`
    expect(output).to eq("generate webpack\n")
  end

  it "allows to invoke a subcommand via an inherited subcomand aliases" do
    output = `foo g webpack`
    expect(output).to eq("generate webpack\n")
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
        before command callback Foo::Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>".", :unused_arguments=>[]}
        before callback (class), 3 arg(s): {:url=>"https://hanamirb.test", :dir=>".", :unused_arguments=>[]}
        before callback (object), 3 arg(s): {:url=>"https://hanamirb.test", :dir=>".", :unused_arguments=>[]}
        dir: ., url: "https://hanamirb.test"
        after command callback Foo::Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>".", :unused_arguments=>[]}
        after callback (class), 3 arg(s): {:url=>"https://hanamirb.test", :dir=>".", :unused_arguments=>[]}
        after callback (object), 3 arg(s): {:url=>"https://hanamirb.test", :dir=>".", :unused_arguments=>[]}
      OUTPUT

      output = `foo callbacks . --url=https://hanamirb.test`
      expect(output).to eq(expected)
    end
  end
end
