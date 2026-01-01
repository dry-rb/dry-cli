# frozen_string_literal: true

RSpec.shared_examples "Third-party gems" do |cli|
  let(:cli) { cli }

  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  it "allows to add a subcommand" do
    output = capture_output { cli.call(arguments: %w[generate webpack]) }
    expect(output).to eq("generate webpack. Apps: []\n")
  end

  it "allows to invoke a subcommand via an inherited subcomand aliases" do
    output = capture_output { cli.call(arguments: %w[g webpack]) }
    expect(output).to eq("generate webpack. Apps: []\n")
  end

  it "allows to override basic commands" do
    output = capture_output { cli.call(arguments: ["hello"]) }
    expect(output).to eq("hello from webpack\n")
  end

  it "allows to override a subcommand" do
    output = capture_output { cli.call(arguments: %w[sub command]) }
    expect(output).to eq("override from webpack\n")
  end

  context "callbacks" do
    it "allows to add callbacks as a block" do
      if RUBY_VERSION < "3.4"
        expected = <<~OUTPUT
          before command callback Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>"."}
          before callback (class), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
          before callback (object), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
          dir: ., url: "https://hanamirb.test"
          after command callback Webpack::CLI::CallbacksCommand {:url=>"https://hanamirb.test", :dir=>"."}
          after callback (class), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
          after callback (object), 2 arg(s): {:url=>"https://hanamirb.test", :dir=>"."}
        OUTPUT

      else
        expected = <<~OUTPUT
          before command callback Webpack::CLI::CallbacksCommand {url: "https://hanamirb.test", dir: "."}
          before callback (class), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
          before callback (object), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
          dir: ., url: "https://hanamirb.test"
          after command callback Webpack::CLI::CallbacksCommand {url: "https://hanamirb.test", dir: "."}
          after callback (class), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
          after callback (object), 2 arg(s): {url: "https://hanamirb.test", dir: "."}
        OUTPUT

      end
      output = capture_output { cli.call(arguments: %w[callbacks . --url=https://hanamirb.test]) }
      expect(output).to eq(expected)
    end
  end

  it "allows to call array option" do
    output = capture_output { cli.call(arguments: %w[generate webpack --apps=test,api,admin]) }
    expect(output).to eq("generate webpack. Apps: [\"test\", \"api\", \"admin\"]\n")
  end
end
