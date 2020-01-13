# frozen_string_literal: true

RSpec.shared_examples 'Rendering' do |cli|
  let(:cli) { cli }

  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  it 'prints required params' do
    output = capture_output { cli.call }
    expected = <<~DESC
      Commands:
        #{cmd} assets [SUBCOMMAND]
        #{cmd} callbacks DIR                       # Command with callbacks
        #{cmd} console                             # Starts Foo console
        #{cmd} db [SUBCOMMAND]
        #{cmd} destroy [SUBCOMMAND]
        #{cmd} exec TASK [DIRS]                    # Execute a task
        #{cmd} generate [SUBCOMMAND]
        #{cmd} greeting [RESPONSE]
        #{cmd} hello                               # Print a greeting
        #{cmd} new PROJECT                         # Generate a new Foo project
        #{cmd} options-with-aliases                # Accepts options with aliases
        #{cmd} routes                              # Print routes
        #{cmd} server                              # Start Foo server (only for development)
        #{cmd} sub [SUBCOMMAND]
        #{cmd} variadic [SUBCOMMAND]
        #{cmd} version                             # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it 'prints required params with labels' do
    output = capture_output { cli.call(arguments: ['destroy']) }

    expected = <<~DESC
      Commands:
        #{cmd} destroy action APP ACTION                    # Destroy an action from app
        #{cmd} destroy app APP                              # Destroy an app
        #{cmd} destroy mailer MAILER                        # Destroy a mailer
        #{cmd} destroy migration MIGRATION                  # Destroy a migration
        #{cmd} destroy model MODEL                          # Destroy a model
    DESC

    expect(output).to eq(expected)
  end

  it 'prints available commands for unknown subcommand' do
    output = capture_output { cli.call(arguments: %w[generate unknown]) }

    expected = <<~DESC
      Commands:
        #{cmd} generate action APP ACTION                     # Generate an action for app
        #{cmd} generate app APP                               # Generate an app
        #{cmd} generate mailer MAILER                         # Generate a mailer
        #{cmd} generate migration MIGRATION                   # Generate a migration
        #{cmd} generate model MODEL                           # Generate a model
        #{cmd} generate secret [APP]                          # Generate session secret
        #{cmd} generate webpack                               # Generate webpack configuration
    DESC

    expect(output).to eq(expected)
  end

  it 'prints available commands for unknown command' do
    output = capture_output { cli.call(arguments: ['unknown']) }

    expected = <<~DESC
      Commands:
        #{cmd} assets [SUBCOMMAND]
        #{cmd} callbacks DIR                       # Command with callbacks
        #{cmd} console                             # Starts Foo console
        #{cmd} db [SUBCOMMAND]
        #{cmd} destroy [SUBCOMMAND]
        #{cmd} exec TASK [DIRS]                    # Execute a task
        #{cmd} generate [SUBCOMMAND]
        #{cmd} greeting [RESPONSE]
        #{cmd} hello                               # Print a greeting
        #{cmd} new PROJECT                         # Generate a new Foo project
        #{cmd} options-with-aliases                # Accepts options with aliases
        #{cmd} routes                              # Print routes
        #{cmd} server                              # Start Foo server (only for development)
        #{cmd} sub [SUBCOMMAND]
        #{cmd} variadic [SUBCOMMAND]
        #{cmd} version                             # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it 'prints first level' do
    output = capture_output { cli.call }

    expected = <<~DESC
      Commands:
        #{cmd} assets [SUBCOMMAND]
        #{cmd} callbacks DIR                       # Command with callbacks
        #{cmd} console                             # Starts Foo console
        #{cmd} db [SUBCOMMAND]
        #{cmd} destroy [SUBCOMMAND]
        #{cmd} exec TASK [DIRS]                    # Execute a task
        #{cmd} generate [SUBCOMMAND]
        #{cmd} greeting [RESPONSE]
        #{cmd} hello                               # Print a greeting
        #{cmd} new PROJECT                         # Generate a new Foo project
        #{cmd} options-with-aliases                # Accepts options with aliases
        #{cmd} routes                              # Print routes
        #{cmd} server                              # Start Foo server (only for development)
        #{cmd} sub [SUBCOMMAND]
        #{cmd} variadic [SUBCOMMAND]
        #{cmd} version                             # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's commands" do
    output = capture_output { cli.call(arguments: ['generate']) }

    expected = <<~DESC
      Commands:
        #{cmd} generate action APP ACTION                     # Generate an action for app
        #{cmd} generate app APP                               # Generate an app
        #{cmd} generate mailer MAILER                         # Generate a mailer
        #{cmd} generate migration MIGRATION                   # Generate a migration
        #{cmd} generate model MODEL                           # Generate a model
        #{cmd} generate secret [APP]                          # Generate session secret
        #{cmd} generate webpack                               # Generate webpack configuration
    DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's subcommand" do
    output = capture_output { cli.call(arguments: %w[generate application]) }

    expected = <<~DESC
      Commands:
        #{cmd} generate action APP ACTION                     # Generate an action for app
        #{cmd} generate app APP                               # Generate an app
        #{cmd} generate mailer MAILER                         # Generate a mailer
        #{cmd} generate migration MIGRATION                   # Generate a migration
        #{cmd} generate model MODEL                           # Generate a model
        #{cmd} generate secret [APP]                          # Generate session secret
        #{cmd} generate webpack                               # Generate webpack configuration
    DESC
    expect(output).to eq(expected)
  end

  it 'prints list options when calling help' do
    output = capture_output { cli.call(arguments: %w[options-with-aliases --help]) }

    expected = <<~DESC
      Command:
        #{cmd} options-with-aliases

      Usage:
        #{cmd} options-with-aliases

      Description:
        Accepts options with aliases

      Options:
        --url=VALUE, -u VALUE           	# The action URL
        --[no-]flag, -f                 	# The flag
        --[no-]opt, -o                  	# The opt, default: false
        --help, -h                      	# Print this help
    DESC

    expect(output).to eq(expected)
  end
end
