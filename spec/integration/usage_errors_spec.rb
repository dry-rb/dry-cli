RSpec.describe 'Usage and Exit Code' do
  let(:command_line) { "#{envar}foo #{argv}" }
  let(:exit_code) do
    system("#{command_line} > /dev/null")
    $?.exitstatus
  end
  let(:output) { `#{command_line}` }

  shared_examples_for :command_that_exits_with_zero_status do
    it 'exits with exit status 0' do
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
      expect(exit_code).to eq 0
    end
  end

  describe 'when -h or --help is provided' do
    let(:envar) { 'PRINT_UNKNOWN_COMMANDS=true ' }
    let(:argv) { '-h' }

    it_behaves_like :command_that_exits_with_zero_status
  end

  describe 'when no command is provided' do
    let(:envar) { '' }
    let(:argv) { '' }

    it_behaves_like :command_that_exits_with_zero_status
  end

  describe 'when an invalid command is provided' do
    let(:envar) { 'PRINT_UNKNOWN_COMMANDS=true ' }
    let(:argv) { 'asdlfjasf' }

    it 'exits with exit status 1' do
      expected = <<~DESC
        Error:
          Unknown command(s): #{argv}

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
      expect(exit_code).to eq 1
    end
  end
end
