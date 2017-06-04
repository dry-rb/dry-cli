RSpec.describe "Basic command" do
  context "commands" do
    it "calls basic command" do
      output = `foo version`
      expect(output).to match("v1.0.0")
    end

    it "calls basic command with alias" do
      output = `foo -v`
      expect(output).to match("v1.0.0")

      output = `foo --version`
      expect(output).to match("v1.0.0")
    end

    it "fails for unknown command" do
      result = system("foo unknown")
      expect(result).to be(false)
    end

    context "works with params" do
      it "without params" do
        output = `foo server`
        expect(output).to match("Server: {}")
      end

      it "a param using space" do
        output = `foo server --port 1234`
        expect(output).to match("Server: {:port=>\"1234\"}")
      end

      it "a param using equal sign" do
        output = `foo server --port=1234`
        expect(output).to match("Server: {:port=>\"1234\"}")
      end

      it "a param using alias" do
        output = `foo server -p 1234`
        expect(output).to match("Server: {:port=>\"1234\"}")
      end

      it "a param with unknown param" do
        output = `foo server --unknown 1234`
        expect(output).to match("Server: {}")
      end

      it "without params" do
        output = `foo server --help`

command_options_help = <<-DESC
Usage: foo server [options]

    -p, --port port                  The port to run the server on
        --server server
        --host host
    -h, --help                       Show this message
DESC
        expect(output).to match(command_options_help)
      end
    end
  end

  context "subcommands" do
    it "calls subcommand" do
      output = `foo generate model`
      expect(output).to match("generated model")
    end

    it "calls subcommand with alias" do
      output = `foo generate --help`
      expect(output).to match("help for generate")
    end

    it "fails for unknown subcommand" do
      result = system("foo generate unknown")
      expect(result).to be(false)
    end
  end

  context "third-party gems" do
    it "allows to override basic commands" do
      output = `foo hello`
      expect(output).to match("world")
    end

    it "allows to add a subcommand" do
      output = `foo generate webpack`
      expect(output).to match("generated configuration")
    end

    it "allows to override a subcommand" do
      output = `foo generate action`
      expect(output).to match("generated action")
    end
  end
end
