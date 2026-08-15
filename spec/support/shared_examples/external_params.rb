# frozen_string_literal: true

RSpec.shared_examples "External params" do |cli|
  let(:cli) { cli }

  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  it "parses an externally added option and passes it to the callbacks that need it" do
    output = capture_output { cli.call(arguments: %w[externally-extended web --skip-tests]) }

    expect(output).to eq(<<~OUTPUT)
      before block: skip_tests: true
      command: name: web, quiet: false
      callback: skip_tests: true, suite: nil
    OUTPUT
  end

  it "applies the externally added option's default when it isn't given" do
    output = capture_output { cli.call(arguments: %w[externally-extended web]) }

    expect(output).to eq(<<~OUTPUT)
      before block: skip_tests: false
      command: name: web, quiet: false
      callback: skip_tests: false, suite: nil
    OUTPUT
  end

  it "keeps the command's own options working" do
    output = capture_output { cli.call(arguments: %w[externally-extended web --quiet --skip-tests]) }

    expect(output).to eq(<<~OUTPUT)
      before block: skip_tests: true
      command: name: web, quiet: true
      callback: skip_tests: true, suite: nil
    OUTPUT
  end

  it "parses an externally added argument" do
    output = capture_output { cli.call(arguments: %w[externally-extended web rspec]) }

    expect(output).to eq(<<~OUTPUT)
      before block: skip_tests: false
      command: name: web, quiet: false
      callback: skip_tests: false, suite: "rspec"
    OUTPUT
  end

  it "lists externally added params alongside the command's own in the help output" do
    output = capture_output { cli.call(arguments: %w[externally-extended --help]) }

    expect(output).to eq(<<~OUTPUT)
      Command:
        #{cmd} externally-extended

      Usage:
        #{cmd} externally-extended NAME [SUITE]

      Description:
        Command extended by third parties

      Arguments:
        NAME          # REQUIRED The name
        SUITE         # Test suite

      Options:
        --quiet       # Be quiet, default: false
        --skip-tests  # Skip test generation, default: false
        --help, -h    # Print this help
    OUTPUT
  end
end
