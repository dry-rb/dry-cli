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
    expect(output).to eq("generate secret: - app: web\n")
  end

  context "works with params" do
    it "without params" do
      output = `foo server`
      expect(output).to eq("Server: {:code_reloading=>true}\n")
    end

    it "a param using space" do
      output = `foo server --server thin`
      expect(output).to eq("Server: {:code_reloading=>true, :server=>\"thin\"}\n")
    end

    it "a param using equal sign" do
      output = `foo server --host=localhost`
      expect(output).to eq("Server: {:code_reloading=>true, :host=>\"localhost\"}\n")
    end

    it "a param using alias" do
      output = `foo server -p 1234`
      expect(output).to eq("Server: {:code_reloading=>true, :port=>\"1234\"}\n")
    end

    it "a param with unknown param" do
      output = `foo server --unknown 1234`
      expect(output).to eq("Error: Invalid param provided\n")
    end

    it "with boolean param" do
      output = `foo server`
      expect(output).to eq("Server: {:code_reloading=>true}\n")

      output = `foo server --no-code-reloading`
      expect(output).to eq("Server: {:code_reloading=>false}\n")
    end

    it "with help param" do
      output = `foo server --help`

command_options_help = <<-DESC
Usage:
  foo server

Description:
  Starts a hanami server

Options:
    -p, --port port                  The port to run the server on
        --server server
        --host host
        --[no-]code-reloading
    -h, --help                       Show this message
DESC
      expect(output).to eq(command_options_help)
    end

    context "with required params" do
      it "can be used" do
        output = `foo new hanami_app`
        expect(output).to eq("New: {} - project_name: hanami_app\n")
      end

      it "with unknown param" do
        output = `foo new hanami_app --unknown 1234`
        expect(output).to eq("Error: Invalid param provided\n")
      end

      it "no required" do
        output = `foo generate secret web`
        expect(output).to eq("generate secret: - app: web\n")

        output = `foo generate secret`
        expect(output).to eq("generate secret: - app: \n")
      end

      it "an error is displayed if there aren't required params" do
        output = `foo new`
        expected_output = <<-DESC
ERROR: "foo new" was called with no arguments
Usage: "foo new PROJECT_NAME"
DESC
        expect(output).to eq(expected_output)
      end
    end
  end
end
