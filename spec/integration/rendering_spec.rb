# frozen_string_literal: true

RSpec.describe 'Rendering' do
  it 'prints available commands for unknown command' do
    output = `foo unknown`

    expected = <<~DESC
      Commands:
        foo assets [SUBCOMMAND]
        foo callbacks DIR                      # Command with callbacks
        foo console                            # Starts Foo console
        foo db [SUBCOMMAND]
        foo destroy [SUBCOMMAND]
        foo exec TASK [DIRS]                   # Execute a task
        foo generate [SUBCOMMAND]
        foo greeting [RESPONSE]
        foo hello                              # Print a greeting
        foo new PROJECT                        # Generate a new Foo project
        foo routes                             # Print routes
        foo server                             # Start Foo server (only for development)
        foo sub [SUBCOMMAND]
        foo variadic [SUBCOMMAND]
        foo version                            # Print Foo version
    DESC

    expect(output).to eq(expected)
  end
end
