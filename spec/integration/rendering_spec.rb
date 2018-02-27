RSpec.describe "Rendering" do
  it "prints required params" do
    output = `foo`

    expected = <<~DESC
      Commands:
        foo assets [SUBCOMMAND]
        foo callbacks DIR                      # Command with callbacks
        foo console                            # Starts Foo console
        foo db [SUBCOMMAND]
        foo destroy [SUBCOMMAND]
        foo generate [SUBCOMMAND]
        foo greeting [RESPONSE]
        foo hello                              # Print a greeting
        foo new PROJECT                        # Generate a new Foo project
        foo routes                             # Print routes
        foo server                             # Start Foo server (only for development)
        foo sub [SUBCOMMAND]
        foo version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it "prints required params with labels" do
    output = `foo destroy`

    expected = <<~DESC
      Commands:
        foo destroy action APP ACTION                   # Destroy an action from app
        foo destroy app APP                             # Destroy an app
        foo destroy mailer MAILER                       # Destroy a mailer
        foo destroy migration MIGRATION                 # Destroy a migration
        foo destroy model MODEL                         # Destroy a model
    DESC

    expect(output).to eq(expected)
  end

  it "prints available commands for unknown subcommand" do
    output = `foo generate unknown`

    expected = <<~DESC
      Commands:
        foo generate action APP ACTION                    # Generate an action for app
        foo generate app APP                              # Generate an app
        foo generate mailer MAILER                        # Generate a mailer
        foo generate migration MIGRATION                  # Generate a migration
        foo generate model MODEL                          # Generate a model
        foo generate secret [APP]                         # Generate session secret
        foo generate webpack                              # Generate webpack configuration
    DESC

    expect(output).to eq(expected)
  end

  it "prints available commands for unknown command" do
    output = `foo unknown`

    expected = <<~DESC
      Commands:
        foo assets [SUBCOMMAND]
        foo callbacks DIR                      # Command with callbacks
        foo console                            # Starts Foo console
        foo db [SUBCOMMAND]
        foo destroy [SUBCOMMAND]
        foo generate [SUBCOMMAND]
        foo greeting [RESPONSE]
        foo hello                              # Print a greeting
        foo new PROJECT                        # Generate a new Foo project
        foo routes                             # Print routes
        foo server                             # Start Foo server (only for development)
        foo sub [SUBCOMMAND]
        foo version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it "prints first level" do
    output = `foo`

    expected = <<~DESC
      Commands:
        foo assets [SUBCOMMAND]
        foo callbacks DIR                      # Command with callbacks
        foo console                            # Starts Foo console
        foo db [SUBCOMMAND]
        foo destroy [SUBCOMMAND]
        foo generate [SUBCOMMAND]
        foo greeting [RESPONSE]
        foo hello                              # Print a greeting
        foo new PROJECT                        # Generate a new Foo project
        foo routes                             # Print routes
        foo server                             # Start Foo server (only for development)
        foo sub [SUBCOMMAND]
        foo version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's commands" do
    output = `foo generate`

    expected = <<~DESC
      Commands:
        foo generate action APP ACTION                    # Generate an action for app
        foo generate app APP                              # Generate an app
        foo generate mailer MAILER                        # Generate a mailer
        foo generate migration MIGRATION                  # Generate a migration
        foo generate model MODEL                          # Generate a model
        foo generate secret [APP]                         # Generate session secret
        foo generate webpack                              # Generate webpack configuration
    DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's subcommand" do
    output = `foo generate application`

    expected = <<~DESC
      Commands:
        foo generate action APP ACTION                    # Generate an action for app
        foo generate app APP                              # Generate an app
        foo generate mailer MAILER                        # Generate a mailer
        foo generate migration MIGRATION                  # Generate a migration
        foo generate model MODEL                          # Generate a model
        foo generate secret [APP]                         # Generate session secret
        foo generate webpack                              # Generate webpack configuration
    DESC
    expect(output).to eq(expected)
  end

  it "prints list options when calling help" do
    output = `foo console --help`

    expected = <<~DESC
      Command:
        foo console

      Usage:
        foo console

      Description:
        Starts Foo console

      Options:
        --engine=VALUE                  	# Force a console engine: (irb/pry/ripl)
        --help, -h                      	# Print this help

      Examples:
        foo console              # Uses the bundled engine
        foo console --engine=pry # Force to use Pry
    DESC

    expect(output).to eq(expected)
  end
end
