# frozen_string_literal: true

RSpec.describe "Third-party gems" do
  it "allows to add callbacks as a block" do
    output = `foo callbacks . --url=https://hanamirb.test`

    if RUBY_VERSION < "3.4"
      expected = <<~OUTPUT
        before command callback Foo::Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>"."}
        before callback (class), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        before callback (object), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        dir: ., url: "https://hanamirb.test"
        after command callback Foo::Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>"."}
        after callback (class), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        after callback (object), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
      OUTPUT
      expect(output).to eq(expected)
    else
      expected = <<~OUTPUT
        before command callback Foo::Webpack::CLI::CallbacksCommand {url: "https://hanamirb.test", dir: "."}
        before callback (class), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
        before callback (object), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
        dir: ., url: "https://hanamirb.test"
        after command callback Foo::Webpack::CLI::CallbacksCommand {url: "https://hanamirb.test", dir: "."}
        after callback (class), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
        after callback (object), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
      OUTPUT
      expect(output).to eq(expected)
    end

  end
end
