# frozen_string_literal: true

RSpec.describe 'Subcommands' do
  it 'calls subcommand' do
    output = `foo generate model`
    expected = <<~DESC
      ERROR: "foo generate model" was called with no arguments
      Usage: "foo generate model MODEL"
    DESC

    expect(output).to eq(expected)
  end

  context 'works with params' do
    it 'without params' do
      output = `foo generate model`
      expected = <<~DESC
        ERROR: "foo generate model" was called with no arguments
        Usage: "foo generate model MODEL"
      DESC

      expect(output).to eq(expected)
    end

    it 'a param using space' do
      output = `foo server --port 2306`
      expect(output).to eq("server - {:code_reloading=>true, :port=>\"2306\"}\n")
    end

    it 'a param using equal sign' do
      output = `foo server --port=2306`
      expect(output).to eq("server - {:code_reloading=>true, :port=>\"2306\"}\n")
    end

    it 'a param using alias' do
      output = `foo server -p 2306`
      expect(output).to eq("server - {:code_reloading=>true, :port=>\"2306\"}\n")
    end

    it 'with help param' do
      output = `foo generate model --help`

      expected = <<~DESC
        Command:
          foo generate model

        Usage:
          foo generate model MODEL

        Description:
          Generate a model

        Arguments:
          MODEL               	# REQUIRED Model name (eg. `user`)

        Options:
          --[no-]skip-migration           	# Skip migration, default: false
          --help, -h                      	# Print this help

        Examples:
          foo generate model user                  # Generate `User` entity, `UserRepository` repository, and the migration
          foo generate model user --skip-migration # Generate `User` entity and `UserRepository` repository
      DESC

      expect(output).to eq(expected)
    end

    context 'with required params' do
      it 'only one param' do
        output = `foo generate model user`
        expect(output).to eq("generate model - model: user\n")
      end

      it 'more than one param' do
        output = `foo destroy action web users#index`
        expect(output).to eq("destroy action - app: web, action: users#index\n")
      end

      it 'more than one param and with optional params' do
        output = `foo generate action web users#index --url=/signin`
        expect(output).to eq("generate action - app: web, action: users#index, options: {:skip_view=>false, :url=>\"/signin\"}\n")
      end

      it 'more than one param and with boolean params' do
        output = `foo generate action web users#index --skip-view --url=/signin`
        expect(output).to eq("generate action - app: web, action: users#index, options: {:skip_view=>true, :url=>\"/signin\"}\n")
      end

      it 'more than required params' do
        output = `foo destroy action web users#index unexpected_param`
        expect(output).to eq("destroy action - app: web, action: users#index\n")
      end

      it "an error is displayed if there aren't required params" do
        output = `foo destroy action`
        expected = <<~DESC
          ERROR: "foo destroy action" was called with no arguments
          Usage: "foo destroy action APP ACTION"
        DESC

        expect(output).to eq(expected)
      end

      it 'an error is displayed if there are some required params' do
        output = `foo destroy action web`
        expected = <<~DESC
          ERROR: "foo destroy action" was called with arguments [\"web\"]
          Usage: "foo destroy action APP ACTION"
        DESC

        expect(output).to eq(expected)
      end

      context 'and a default value' do
        it 'returns the default value if nothing is passed' do
          output = `foo db rollback`

          expect(output).to eq("1\n")
        end

        it 'returns the passed value' do
          output = `foo db rollback 3`

          expect(output).to eq("3\n")
        end
      end
    end
  end
end
