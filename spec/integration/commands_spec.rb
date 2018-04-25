RSpec.describe "Commands" do
  it "calls basic command" do
    output = `foo version`
    expect(output).to eq("v1.0.0\n")
  end

  it "calls basic command with alias" do
    output = `foo v`
    expect(output).to eq("v1.0.0\n")

    output = `foo -v`
    expect(output).to eq("v1.0.0\n")

    output = `foo --version`
    expect(output).to eq("v1.0.0\n")
  end

  it "calls subcommand via intermediate alias" do
    output = `foo g secret web`
    expect(output).to eq("generate secret - app: web\n")
  end

  context "works with params" do
    it "without params" do
      output = `foo server`
      expect(output).to eq("server - {:code_reloading=>true}\n")
    end

    it "a param using space" do
      output = `foo server --server thin`
      expect(output).to eq("server - {:code_reloading=>true, :server=>\"thin\"}\n")
    end

    it "a param using equal sign" do
      output = `foo server --host=localhost`
      expect(output).to eq("server - {:code_reloading=>true, :host=>\"localhost\"}\n")
    end

    it "a param using alias" do
      output = `foo server -p 1234`
      expect(output).to eq("server - {:code_reloading=>true, :port=>\"1234\"}\n")
    end

    it "a param with unknown param" do
      output = `foo server --unknown 1234`
      expect(output).to eq("Error: \"server\" was called with arguments \"--unknown 1234\"\n")
    end

    it "with boolean param" do
      output = `foo server`
      expect(output).to eq("server - {:code_reloading=>true}\n")

      output = `foo server --no-code-reloading`
      expect(output).to eq("server - {:code_reloading=>false}\n")
    end

    context "with supported values" do
      context "and with supported value passed" do
        it "call the command with the option" do
          output = `foo console --engine=pry`
          expect(output).to eq("console - engine: pry\n")
        end
      end

      context "and with an unknown value passed" do
        it "prints error" do
          output = `foo console --engine=unknown`
          expect(output).to eq("Error: \"console\" was called with arguments \"--engine=unknown\"\n")
        end
      end
    end

    it "with help param" do
      output = `foo server --help`

      expected = <<~DESC
        Command:
          foo server

        Usage:
          foo server

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
          foo server                     # Basic usage (it uses the bundled server engine)
          foo server --server=webrick    # Force `webrick` server engine
          foo server --host=0.0.0.0      # Bind to a host
          foo server --port=2306         # Bind to a port
          foo server --no-code-reloading # Disable code reloading
      DESC

      expect(output).to eq(expected)
    end

    context "with required params" do
      it "can be used" do
        output = `foo new bookshelf`
        expect(output).to eq("new - project: bookshelf\n")
      end

      it "with unknown param" do
        output = `foo new bookshelf --unknown 1234`
        expect(output).to eq("Error: \"new\" was called with arguments \"bookshelf --unknown 1234\"\n")
      end

      it "no required" do
        output = `foo generate secret web`
        expect(output).to eq("generate secret - app: web\n")

        output = `foo generate secret`
        expect(output).to eq("generate secret - app: \n")
      end

      it "an error is displayed if there aren't required params" do
        output = `foo new`
        expected_output = <<~DESC
          ERROR: "foo new" was called with no arguments
          Usage: "foo new PROJECT"
        DESC
        expect(output).to eq(expected_output)
      end

      it "with default value and using options" do
        output = `foo greeting --person=Alfonso`
        expect(output).to eq("response: Hello World, person: Alfonso\n")

        output = `foo greeting bye --person=Alfonso`
        expect(output).to eq("response: bye, person: Alfonso\n")
      end
    end
  end
end
