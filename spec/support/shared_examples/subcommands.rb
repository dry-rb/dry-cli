# frozen_string_literal: true

RSpec.shared_examples "Subcommands" do |cli|
  let(:cli) { cli }

  let(:cmd) { File.basename($PROGRAM_NAME, File.extname($PROGRAM_NAME)) }

  it "calls subcommand" do
    error = capture_error { cli.call(arguments: %w[generate model]) }
    expected = <<~DESC
      ERROR: "#{cmd} generate model" was called with no arguments
      Usage: "#{cmd} generate model MODEL"
    DESC

    expect(error).to eq(expected)
  end

  context "works with params" do
    it "without params" do
      error = capture_error { cli.call(arguments: %w[generate model]) }
      expected = <<~DESC
        ERROR: "#{cmd} generate model" was called with no arguments
        Usage: "#{cmd} generate model MODEL"
      DESC

      expect(error).to eq(expected)
    end

    it "a param using space" do
      output = capture_output { cli.call(arguments: %w[server --port 2306]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "server - {:code_reloading=>true, :deps=>[\"dep1\", \"dep2\"], :port=>\"2306\"}\n"
        )

      else
        expect(output).to eq(
          "server - {code_reloading: true, deps: [\"dep1\", \"dep2\"], port: \"2306\"}\n"
        )
      end
    end

    it "a param using equal sign" do
      output = capture_output { cli.call(arguments: %w[server --port=2306]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "server - {:code_reloading=>true, :deps=>[\"dep1\", \"dep2\"], :port=>\"2306\"}\n"
        )
      else
        expect(output).to eq(
          "server - {code_reloading: true, deps: [\"dep1\", \"dep2\"], port: \"2306\"}\n"
        )
      end
    end

    it "a param using alias" do
      output = capture_output { cli.call(arguments: %w[server -p 2306]) }

      if RUBY_VERSION < "3.4"
        expect(output).to eq(
          "server - {:code_reloading=>true, :deps=>[\"dep1\", \"dep2\"], :port=>\"2306\"}\n"
        )
      else
        expect(output).to eq(
          "server - {code_reloading: true, deps: [\"dep1\", \"dep2\"], port: \"2306\"}\n"
        )
      end
    end

    it "with help param" do
      output = capture_output { cli.call(arguments: %w[generate model --help]) }

      expected = <<~DESC
        Command:
          #{cmd} generate model

        Usage:
          #{cmd} generate model MODEL

        Description:
          Generate a model

        Arguments:
          MODEL                                       # REQUIRED Model name (eg. `user`)

        Options:
          --[no-]skip-migration                       # Skip migration, default: false
          --help, -h                                  # Print this help

        Examples:
          #{cmd} generate model user                   # Generate `User` entity, `UserRepository` repository, and the migration
          #{cmd} generate model user --skip-migration  # Generate `User` entity and `UserRepository` repository
      DESC
      expect(output).to eq(expected)
    end

    context "with required params" do
      it "only one param" do
        output = capture_output { cli.call(arguments: %w[generate model user]) }
        expect(output).to eq("generate model - model: user\n")
      end

      it "more than one param" do
        output = capture_output { cli.call(arguments: %w[destroy action web users#index]) }
        expect(output).to eq("destroy action - app: web, action: users#index\n")
      end

      it "more than one param and with optional params" do
        output = capture_output { cli.call(arguments: %w[generate action web users#index --url=/signin]) }

        if RUBY_VERSION < "3.4"
          expect(output).to eq("generate action - app: web, action: users#index, options: {:skip_view=>false, :url=>\"/signin\"}\n")
        else
          expect(output).to eq("generate action - app: web, action: users#index, options: {skip_view: false, url: \"/signin\"}\n")
        end
      end

      it "more than one param and with boolean params" do
        output = capture_output { cli.call(arguments: %w[generate action web users#index --skip-view --url=/signin]) }

        if RUBY_VERSION < "3.4"
          expect(output).to eq("generate action - app: web, action: users#index, options: {:skip_view=>true, :url=>\"/signin\"}\n")
        else
          expect(output).to eq("generate action - app: web, action: users#index, options: {skip_view: true, url: \"/signin\"}\n")
        end
      end

      it "more than required params" do
        output = capture_output { cli.call(arguments: %w[destroy action web users#index unexpected_param]) }
        expect(output).to eq("destroy action - app: web, action: users#index\n")
      end

      it "an error is displayed if there aren't required params" do
        error = capture_error { cli.call(arguments: %w[destroy action]) }
        expected = <<~DESC
          ERROR: "#{cmd} destroy action" was called with no arguments
          Usage: "#{cmd} destroy action APP ACTION"
        DESC

        expect(error).to eq(expected)
      end

      it "an error is displayed if there are some required params" do
        error = capture_error { cli.call(arguments: %w[destroy action web]) }
        expected = <<~DESC
          ERROR: "#{cmd} destroy action" was called with arguments [\"web\"]
          Usage: "#{cmd} destroy action APP ACTION"
        DESC

        expect(error).to eq(expected)
      end

      context "and a default value" do
        it "returns the default value if nothing is passed" do
          output = capture_output { cli.call(arguments: %w[db rollback]) }

          expect(output).to eq("1\n")
        end

        it "returns the passed value" do
          output = capture_output { cli.call(arguments: %w[db rollback 3]) }

          expect(output).to eq("3\n")
        end
      end
    end
  end

  context "works with root command" do
    it "shows help" do
      output = capture_output { cli.call(arguments: %w[root-command sub-command -h]) }
      expected = <<~DESC
        Command:
          #{cmd} root-command sub-command

        Usage:
          #{cmd} root-command sub-command ROOT_COMMAND_SUB_COMMAND_ARGUMENT

        Description:
          Root command sub command

        Arguments:
          ROOT_COMMAND_SUB_COMMAND_ARGUMENT        # REQUIRED Root command sub command argument

        Options:
          --root-command-sub-command-option=VALUE  # Root command sub command option
          --help, -h                               # Print this help
      DESC
      expect(output).to eq(expected)

      output = capture_output { cli.call(arguments: %w[root-command sub-command --help]) }
      expect(output).to eq(expected)
    end

    context "works with params" do
      it "without params" do
        error = capture_error { cli.call(arguments: %w[root-command sub-command]) }
        expected = <<~DESC
          ERROR: "rspec root-command sub-command" was called with no arguments
          Usage: "rspec root-command sub-command ROOT_COMMAND_SUB_COMMAND_ARGUMENT"
        DESC

        expect(error).to eq(expected)
      end

      it "with params" do
        output = capture_output {
          cli.call(arguments: ["root-command", "sub-command", '"hello world"'])
        }
        expected = <<~DESC
          I'm a root-command sub-command argument:"hello world"
          I'm a root-command sub-command option:
        DESC

        expect(output).to eq(expected)
      end

      it "with option using space" do
        output = capture_output {
          cli.call(arguments: [
            "root-command",
            "sub-command",
            '"hello world"',
            "--root-command-sub-command-option",
            '"bye world"'
          ])
        }
        expected = <<~DESC
          I'm a root-command sub-command argument:"hello world"
          I'm a root-command sub-command option:"bye world"
        DESC

        expect(output).to eq(expected)
      end

      it "with option using equal sign" do
        output = capture_output {
          cli.call(arguments: [
            "root-command",
            "sub-command",
            '"hello world"',
            '--root-command-sub-command-option="bye world"'
          ])
        }
        expected = <<~DESC
          I'm a root-command sub-command argument:"hello world"
          I'm a root-command sub-command option:"bye world"
        DESC

        expect(output).to eq(expected)
      end
    end
  end
end
