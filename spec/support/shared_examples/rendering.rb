# frozen_string_literal: true

RSpec.shared_examples 'Rendering' do |cmd|
  let(:cmd) { cmd }

  it 'prints required params' do
    output = `#{cmd}`

    expected = <<~DESC
      Commands:
        #{cmd} assets [SUBCOMMAND]
        #{cmd} callbacks DIR                      # Command with callbacks
        #{cmd} console                            # Starts Foo console
        #{cmd} db [SUBCOMMAND]
        #{cmd} destroy [SUBCOMMAND]
        #{cmd} exec TASK [DIRS]                   # Execute a task
        #{cmd} generate [SUBCOMMAND]
        #{cmd} greeting [RESPONSE]
        #{cmd} hello                              # Print a greeting
        #{cmd} new PROJECT                        # Generate a new Foo project
        #{cmd} routes                             # Print routes
        #{cmd} server                             # Start Foo server (only for development)
        #{cmd} sub [SUBCOMMAND]
        #{cmd} variadic [SUBCOMMAND]
        #{cmd} version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it 'prints required params with labels' do
    output = `#{cmd} destroy`

    expected = <<~DESC
      Commands:
        #{cmd} destroy action APP ACTION                   # Destroy an action from app
        #{cmd} destroy app APP                             # Destroy an app
        #{cmd} destroy mailer MAILER                       # Destroy a mailer
        #{cmd} destroy migration MIGRATION                 # Destroy a migration
        #{cmd} destroy model MODEL                         # Destroy a model
    DESC

    expect(output).to eq(expected)
  end

  it 'prints available commands for unknown subcommand' do
    output = `#{cmd} generate unknown`

    expected = <<~DESC
      Commands:
        #{cmd} generate action APP ACTION                    # Generate an action for app
        #{cmd} generate app APP                              # Generate an app
        #{cmd} generate mailer MAILER                        # Generate a mailer
        #{cmd} generate migration MIGRATION                  # Generate a migration
        #{cmd} generate model MODEL                          # Generate a model
        #{cmd} generate secret [APP]                         # Generate session secret
        #{cmd} generate webpack                              # Generate webpack configuration
    DESC

    expect(output).to eq(expected)
  end

  it 'prints available commands for unknown command' do
    output = `#{cmd} unknown`

    expected = <<~DESC
      Commands:
        #{cmd} assets [SUBCOMMAND]
        #{cmd} callbacks DIR                      # Command with callbacks
        #{cmd} console                            # Starts Foo console
        #{cmd} db [SUBCOMMAND]
        #{cmd} destroy [SUBCOMMAND]
        #{cmd} exec TASK [DIRS]                   # Execute a task
        #{cmd} generate [SUBCOMMAND]
        #{cmd} greeting [RESPONSE]
        #{cmd} hello                              # Print a greeting
        #{cmd} new PROJECT                        # Generate a new Foo project
        #{cmd} routes                             # Print routes
        #{cmd} server                             # Start Foo server (only for development)
        #{cmd} sub [SUBCOMMAND]
        #{cmd} variadic [SUBCOMMAND]
        #{cmd} version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it 'prints first level' do
    output = `#{cmd}`

    expected = <<~DESC
      Commands:
        #{cmd} assets [SUBCOMMAND]
        #{cmd} callbacks DIR                      # Command with callbacks
        #{cmd} console                            # Starts Foo console
        #{cmd} db [SUBCOMMAND]
        #{cmd} destroy [SUBCOMMAND]
        #{cmd} exec TASK [DIRS]                   # Execute a task
        #{cmd} generate [SUBCOMMAND]
        #{cmd} greeting [RESPONSE]
        #{cmd} hello                              # Print a greeting
        #{cmd} new PROJECT                        # Generate a new Foo project
        #{cmd} routes                             # Print routes
        #{cmd} server                             # Start Foo server (only for development)
        #{cmd} sub [SUBCOMMAND]
        #{cmd} variadic [SUBCOMMAND]
        #{cmd} version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's commands" do
    output = `#{cmd} generate`

    expected = <<~DESC
      Commands:
        #{cmd} generate action APP ACTION                    # Generate an action for app
        #{cmd} generate app APP                              # Generate an app
        #{cmd} generate mailer MAILER                        # Generate a mailer
        #{cmd} generate migration MIGRATION                  # Generate a migration
        #{cmd} generate model MODEL                          # Generate a model
        #{cmd} generate secret [APP]                         # Generate session secret
        #{cmd} generate webpack                              # Generate webpack configuration
    DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's subcommand" do
    output = `#{cmd} generate application`

    expected = <<~DESC
      Commands:
        #{cmd} generate action APP ACTION                    # Generate an action for app
        #{cmd} generate app APP                              # Generate an app
        #{cmd} generate mailer MAILER                        # Generate a mailer
        #{cmd} generate migration MIGRATION                  # Generate a migration
        #{cmd} generate model MODEL                          # Generate a model
        #{cmd} generate secret [APP]                         # Generate session secret
        #{cmd} generate webpack                              # Generate webpack configuration
    DESC
    expect(output).to eq(expected)
  end

  it 'prints list options when calling help' do
    output = `#{cmd} console --help`

    expected = <<~DESC
      Command:
        #{cmd} console

      Usage:
        #{cmd} console

      Description:
        Starts Foo console

      Options:
        --engine=VALUE                  	# Force a console engine: (irb/pry/ripl)
        --help, -h                      	# Print this help

      Examples:
        #{cmd} console              # Uses the bundled engine
        #{cmd} console --engine=pry # Force to use Pry
    DESC

    expect(output).to eq(expected)
  end
end
