# frozen_string_literal: true

RSpec.describe "Error output" do
  let(:deploy_command) do
    Class.new(Dry::CLI::Command) do
      argument :app, required: true
      argument :target, required: true
      option :mode, values: %w[fast safe]
      option :tags, type: :array, values: %w[a b]
      option :port, cast: ->(v) { Integer(v) }
      option :token, required: true, aliases: %w[t]
      option :verbose, type: :boolean
      option :version_check, type: :boolean

      def call(**options) = stdout.puts(options.keys.sort.join(","))
    end
  end

  let(:rollback_command) do
    Class.new(Dry::CLI::Command) do
      argument :steps, values: %w[1 2 3]

      def call(**) = stdout.puts("rollback")
    end
  end

  let(:cli) do
    deploy_command = self.deploy_command
    rollback_command = self.rollback_command
    server_command = Class.new(Dry::CLI::Command) { def call(**) = stdout.puts("server") }

    Dry::CLI.new do |c|
      c.register "deploy", deploy_command
      c.register "server", server_command
      c.register "db rollback", rollback_command
    end
  end

  let(:exit_codes) { [] }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  def call_cli(*arguments)
    cli.call(arguments:, stdout:, stderr:, exit: ->(code) { exit_codes << code })
  end

  # Returns the given error lines, followed by the usage line and help hint for `deploy`.
  def with_deploy_usage(message)
    <<~ERROR
      #{message}

      Usage: rspec deploy APP TARGET --token=VALUE
      Run "rspec deploy --help" for more information.
    ERROR
  end

  it "names missing arguments and options, one line for each" do
    call_cli("deploy")

    expect(stderr.string).to eq with_deploy_usage(<<~ERROR.chomp)
      Error: missing required arguments APP, TARGET
      Error: missing required option --token
    ERROR
    expect(exit_codes).to eq [1]
  end

  it "names a missing argument" do
    call_cli("deploy", "a", "--token=x")

    expect(stderr.string).to eq with_deploy_usage("Error: missing required argument TARGET")
  end

  it "says when an option needs a value" do
    call_cli("deploy", "a", "b", "--token")

    expect(stderr.string).to eq with_deploy_usage("Error: option --token needs a value")
  end

  it "names an option alias as the user typed it" do
    call_cli("deploy", "a", "b", "-t")

    expect(stderr.string).to eq with_deploy_usage("Error: option -t needs a value")
  end

  it "says when an option doesn't take a value" do
    call_cli("deploy", "a", "b", "--token=x", "--verbose=yes")

    expect(stderr.string).to eq with_deploy_usage("Error: option --verbose doesn't take a value")
  end

  it "names an unknown option" do
    call_cli("deploy", "a", "b", "--token=x", "--nope=1")

    expect(stderr.string).to eq with_deploy_usage("Error: unknown option --nope")
  end

  it "does not accept abbreviated options", if: Dry::CLI::Parser::EXACT_OPTIONS do
    call_cli("deploy", "a", "b", "--token=x", "--verb")

    expect(stderr.string).to eq with_deploy_usage("Error: unknown option --verb")
    expect(stdout.string).to eq ""
  end

  it "names an ambiguous abbreviated option, before optparse 0.5", unless: Dry::CLI::Parser::EXACT_OPTIONS do
    call_cli("deploy", "a", "b", "--token=x", "--ver")

    expect(stderr.string).to eq with_deploy_usage("Error: ambiguous option --ver")
  end

  it "lists the accepted values for an invalid option value" do
    call_cli("deploy", "a", "b", "--token=x", "--mode", "slow")

    expect(stderr.string).to eq with_deploy_usage(%(Error: invalid value "slow" for --mode; accepted values: fast, safe))
  end

  it "accepts a valid option value" do
    call_cli("deploy", "a", "b", "--token=x", "--mode=fast")

    expect(stdout.string).to eq "app,mode,target,token\n"
    expect(exit_codes).to eq []
  end

  it "names only the invalid values of an array option" do
    call_cli("deploy", "a", "b", "--token=x", "--tags=a,c,d")

    expect(stderr.string).to eq with_deploy_usage(%(Error: invalid values "c", "d" for --tags; accepted values: a, b))
  end

  it "names the value that could not be cast, followed by the cast error" do
    call_cli("deploy", "a", "b", "--token=x", "--port=abc")

    expect(stderr.string).to eq with_deploy_usage(%(Error: invalid value "abc" for --port: invalid value for Integer(): "abc"))
  end

  it "names an argument the way the usage line does" do
    call_cli("db", "rollback", "4")

    expect(stderr.string).to eq <<~ERROR
      Error: invalid value "4" for STEPS; accepted values: 1, 2, 3

      Usage: rspec db rollback [STEPS]
      Run "rspec db rollback --help" for more information.
    ERROR
  end

  describe "styling" do
    around do |example|
      Dry::CLI::Style.enabled = true
      Dry::CLI::Style.color_level = :ansi16
      example.run
    ensure
      Dry::CLI::Style.enabled = nil
      Dry::CLI::Style.color_level = nil
    end

    it "shows the error label in bold red when stderr can show color" do
      call_cli("deploy", "a", "--token=x")

      expect(stderr.string).to start_with "\e[1;31mError:\e[0m missing required argument TARGET\n"
    end

    it "shows the error label for an unknown command in bold red" do
      call_cli("serve")

      expect(stderr.string).to start_with "\e[1;31mError:\e[0m unknown command \"serve\""
    end
  end

  describe "unknown commands" do
    it "suggests a similar command by its full name" do
      call_cli("db", "rollbak")

      expect(stderr.string).to eq <<~ERROR
        Error: unknown command "rollbak". Did you mean "rspec db rollback"?

        Commands:
          rspec db rollback [STEPS]
      ERROR
      expect(exit_codes).to eq [1]
    end

    it "names an unknown command with no similar command" do
      call_cli("xyz")

      expect(stderr.string).to start_with %(Error: unknown command "xyz"\n\nCommands:\n)
      expect(exit_codes).to eq [1]
    end
  end

  describe "options with no command" do
    it "names an unknown option given to the CLI" do
      call_cli("--nope=1")

      expect(stderr.string).to start_with %(Error: unknown option --nope\n\nCommands:\n  rspec db [SUBCOMMAND]\n)
      expect(stdout.string).to eq ""
      expect(exit_codes).to eq [1]
    end

    it "names an unknown option given to a prefix" do
      call_cli("db", "-x")

      expect(stderr.string).to eq <<~ERROR
        Error: unknown option -x

        Commands:
          rspec db rollback [STEPS]
      ERROR
      expect(exit_codes).to eq [1]
    end

    it "lists the commands on stdout for --help" do
      call_cli("--help")

      expect(stdout.string).to start_with "Commands:\n  rspec db [SUBCOMMAND]\n"
      expect(stderr.string).to eq ""
      expect(exit_codes).to eq []
    end

    it "lists a prefix's commands on stdout for -h" do
      call_cli("db", "-h")

      expect(stdout.string).to eq "Commands:\n  rspec db rollback [STEPS]\n"
      expect(stderr.string).to eq ""
      expect(exit_codes).to eq []
    end
  end

  describe "a prefix with no command" do
    it "lists its commands on stdout" do
      call_cli("db")

      expect(stdout.string).to eq "Commands:\n  rspec db rollback [STEPS]\n"
      expect(stderr.string).to eq ""
      expect(exit_codes).to eq []
    end
  end
end
