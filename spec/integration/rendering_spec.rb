RSpec.describe "Rendering" do
  it "prints required params" do
    output = `foo`

    expected = <<-DESC
Commands:
  foo destroy [SUBCOMMAND]
  foo generate [SUBCOMMAND]
  foo hello
  foo new PROJECT_NAME                   # Creates a new hanami project
  foo server                             # Starts a hanami server
  foo version
DESC

    expect(output).to eq(expected)
  end

  it "prints required params with labels" do
    output = `foo destroy`

    expected = <<-DESC
Commands:
  foo destroy action APPLICATION_NAME CONTROLLER_NAME__ACTION_NAME
DESC

    expect(output).to eq(expected)
  end

  it "prints available commands for unknown subcommand" do
    output = `foo generate unknown`

    expected = <<-DESC
Commands:
  foo generate action                                      # Generate an action
  foo generate application [SUBCOMMAND]
  foo generate model MODEL_NAME                            # Generate an entity
  foo generate secret
  foo generate webpack
DESC

    expect(output).to eq(expected)
  end

it "prints available commands for unknown command" do
    output = `foo unknown`

    expected = <<-DESC
Commands:
  foo destroy [SUBCOMMAND]
  foo generate [SUBCOMMAND]
  foo hello
  foo new PROJECT_NAME                   # Creates a new hanami project
  foo server                             # Starts a hanami server
  foo version
DESC

    expect(output).to eq(expected)
  end

  it "prints first level" do
    output = `foo`

    expected = <<-DESC
Commands:
  foo destroy [SUBCOMMAND]
  foo generate [SUBCOMMAND]
  foo hello
  foo new PROJECT_NAME                   # Creates a new hanami project
  foo server                             # Starts a hanami server
  foo version
DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's commands" do
    output = `foo generate`

    expected = <<-DESC
Commands:
  foo generate action                                      # Generate an action
  foo generate application [SUBCOMMAND]
  foo generate model MODEL_NAME                            # Generate an entity
  foo generate secret
  foo generate webpack
DESC

    expect(output).to eq(expected)
  end

  it "prints subcommand's subcommand" do
    output = `foo generate application`

    expected = <<-DESC
Commands:
  foo generate application new                 # Generate an application
DESC
    expect(output).to eq(expected)
  end
end
