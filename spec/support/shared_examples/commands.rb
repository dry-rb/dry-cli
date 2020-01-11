# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
RSpec.shared_examples 'Commands' do |cli|
  let(:cli) { cli }

  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  it 'calls basic command' do
    output = capture_output { cli.call(arguments: ['version']) }
    expect(output).to eq("v1.0.0\n")
  end

  it 'calls basic command with alias' do
    output = capture_output { cli.call(arguments: ['v']) }
    expect(output).to eq("v1.0.0\n")

    output = capture_output { cli.call(arguments: ['-v']) }
    expect(output).to eq("v1.0.0\n")

    output = capture_output { cli.call(arguments: ['--version']) }
    expect(output).to eq("v1.0.0\n")
  end

  it 'calls subcommand via intermediate alias' do
    output = capture_output { cli.call(arguments: %w[g secret web]) }
    expect(output).to eq("generate secret - app: web\n")
  end

  context 'works with params' do
    it 'without params' do
      output = capture_output { cli.call(arguments: ['server']) }
      expect(output).to eq("server - {:code_reloading=>true}\n")
    end

    it 'a param using space' do
      output = capture_output { cli.call(arguments: %w[server --server thin]) }
      expect(output).to eq("server - {:code_reloading=>true, :server=>\"thin\"}\n")
    end

    it 'a param using equal sign' do
      output = capture_output { cli.call(arguments: %w[server --host=localhost]) }
      expect(output).to eq("server - {:code_reloading=>true, :host=>\"localhost\"}\n")
    end

    it 'a param using alias' do
      output = capture_output { cli.call(arguments: %w[options-with-aliases -u test]) }
      expect(output).to eq("options with aliases - {:opt=>false, :url=>\"test\"}\n")

      output = capture_output { cli.call(arguments: %w[options-with-aliases -utest]) }
      expect(output).to eq("options with aliases - {:opt=>false, :url=>\"test\"}\n")

      output = capture_output { cli.call(arguments: %w[options-with-aliases -f -u test]) }
      expect(output).to eq("options with aliases - {:opt=>false, :flag=>true, :url=>\"test\"}\n")

      output = capture_output { cli.call(arguments: %w[options-with-aliases -o]) }
      expect(output).to eq("options with aliases - {:opt=>true}\n")

      output = capture_output { cli.call(arguments: %w[options-with-aliases -of]) }
      expect(output).to eq("options with aliases - {:opt=>true, :flag=>true}\n")
    end

    it 'a param with unknown param' do
      output = capture_output { cli.call(arguments: %w[server --unknown 1234]) }
      expect(output).to eq("Error: \"server\" was called with arguments \"--unknown 1234\"\n")
    end

    it 'with boolean param' do
      output = capture_output { cli.call(arguments: ['server']) }
      expect(output).to eq("server - {:code_reloading=>true}\n")

      output = capture_output { cli.call(arguments: %w[server --no-code-reloading]) }
      expect(output).to eq("server - {:code_reloading=>false}\n")
    end

    context 'with array param' do
      it 'allows to omit optional array argument' do
        output = capture_output { cli.call(arguments: %w[exec test]) }
        expect(output).to eq("exec - Task: test - Directories: []\n")
      end

      it 'capture all the remaining arguments' do
        output = capture_output { cli.call(arguments: %w[exec test api admin]) }
        expect(output).to eq("exec - Task: test - Directories: [\"api\", \"admin\"]\n")
      end
    end

    context 'with supported values' do
      context 'and with supported value passed' do
        it 'call the command with the option' do
          output = capture_output { cli.call(arguments: %w[console --engine=pry]) }
          expect(output).to eq("console - engine: pry\n")
        end
      end

      context 'and with an unknown value passed' do
        it 'prints error' do
          output = capture_output { cli.call(arguments: %w[console --engine=unknown]) }
          expect(output).to eq("Error: \"console\" was called with arguments \"--engine=unknown\"\n") # rubocop:disable Metrics/LineLength
        end
      end
    end

    it 'with help param' do
      output = capture_output { cli.call(arguments: %w[server --help]) }

      expected = <<~DESC
        Command:
          #{cmd} server

        Usage:
          #{cmd} server

        Description:
          Start Foo server (only for development)

        Options:
          --server=VALUE                  	# Force a server engine (eg, webrick, puma, thin, etc..)
          --host=VALUE                    	# The host address to bind to
          --port=VALUE, -p VALUE          	# The port to run the server on
          --debug=VALUE                   	# Turn on debug output
          --warn=VALUE                    	# Turn on warnings
          --daemonize=VALUE               	# Daemonize the server
          --pid=VALUE                     	# Path to write a pid file after daemonize
          --[no-]code-reloading           	# Code reloading, default: true
          --help, -h                      	# Print this help

        Examples:
          #{cmd} server                     # Basic usage (it uses the bundled server engine)
          #{cmd} server --server=webrick    # Force `webrick` server engine
          #{cmd} server --host=0.0.0.0      # Bind to a host
          #{cmd} server --port=2306         # Bind to a port
          #{cmd} server --no-code-reloading # Disable code reloading
      DESC

      expect(output).to eq(expected)
    end

    context 'with required params' do
      it 'can be used' do
        output = capture_output { cli.call(arguments: %w[new bookshelf]) }
        expect(output).to eq("new - project: bookshelf\n")
      end

      it 'with unknown param' do
        output = capture_output { cli.call(arguments: %w[new bookshelf --unknown 1234]) }
        expect(output).to eq("Error: \"new\" was called with arguments \"bookshelf --unknown 1234\"\n") # rubocop:disable Metrics/LineLength
      end

      it 'no required' do
        output = capture_output { cli.call(arguments: %w[generate secret web]) }
        expect(output).to eq("generate secret - app: web\n")

        output = capture_output { cli.call(arguments: %w[generate secret]) }
        expect(output).to eq("generate secret - app: \n")
      end

      it "an error is displayed if there aren't required params" do
        output = capture_output { cli.call(arguments: ['new']) }
        expected_output = <<~DESC
          ERROR: "#{cmd} new" was called with no arguments
          Usage: "#{cmd} new PROJECT"
        DESC
        expect(output).to eq(expected_output)
      end

      it 'with default value and using options' do
        output = capture_output { cli.call(arguments: %w[greeting --person=Alfonso]) }
        expect(output).to eq("response: Hello World, person: Alfonso\n")

        output = capture_output { cli.call(arguments: %w[greeting bye --person=Alfonso]) }
        expect(output).to eq("response: bye, person: Alfonso\n")
      end
    end

    context 'with extra params' do
      it 'is accessible via options[:args]' do
        output = capture_output { cli.call(arguments: %w[variadic default bar baz]) }
        expect(output).to eq("Unused Arguments: bar, baz\n")
      end

      context 'when there is a required argument' do
        it 'parses both separately' do
          output = capture_output { cli.call(arguments: ['variadic', 'with-mandatory', cmd, 'bar', 'baz']) }
          expect(output).to eq("first: #{cmd}\nUnused Arguments: bar, baz\n")
        end

        context 'and there are options' do
          it 'parses both separately' do
            output = capture_output { cli.call(arguments: ['variadic', 'with-mandatory-and-options', cmd, 'bar', 'baz']) }
            expect(output).to eq("first: #{cmd}\nurl: \nmethod: \nUnused Arguments: bar, baz\n")

            output = capture_output { cli.call(arguments: ['variadic', 'with-mandatory-and-options', '--url=root', '--method=index', cmd, 'bar', 'baz']) }
            expect(output).to eq("first: #{cmd}\nurl: root\nmethod: index\nUnused Arguments: bar, baz\n")

            output = capture_output { cli.call(arguments: %w[variadic with-mandatory-and-options uno -- due tre --blah]) }
            expect(output).to eq("first: uno\nurl: \nmethod: \nUnused Arguments: due, tre, --blah\n")
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
