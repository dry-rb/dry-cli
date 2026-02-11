# frozen_string_literal: true

require "open3"

RSpec.describe "Spell checker" do
  it "print similar command when there is a command with a typo" do
    _, stderr, = Open3.capture3("foo routs")

    expected = <<~DESC
      I don't know how to 'routs'. Did you mean: 'routes' ?

      Commands:
        foo -c PREFIX                                              # Help you to build a shell completion script by searching commands based on a prefix
        foo assets [SUBCOMMAND]
        foo callbacks DIR                                          # Command with callbacks
        foo console                                                # Starts Foo console
        foo db [SUBCOMMAND]
        foo destroy [SUBCOMMAND]
        foo exec TASK DIRS                                         # Execute a task
        foo generate [SUBCOMMAND]
        foo greeting [RESPONSE]
        foo hello                                                  # Print a greeting
        foo nested [SUBCOMMAND]
        foo new PROJECT                                            # Generate a new Foo project
        foo root-command [ARGUMENT|SUBCOMMAND]                     # Root command with arguments and subcommands
        foo routes                                                 # Print routes
        foo server                                                 # Start Foo server (only for development)
        foo sub [SUBCOMMAND]
        foo variadic [SUBCOMMAND]
        foo version                                                # Print Foo version
    DESC

    expect(stderr).to eq(expected)
  end

  it "handles typos in subcommands" do
    _, stderr, = Open3.capture3("foo sub comand")

    expected = <<~DESC
      I don't know how to 'comand'. Did you mean: 'command' ?

      Commands:
        foo sub command         # Override a subcommand
    DESC

    expect(stderr).to eq(expected)
  end
end
