RSpec.describe "Subcommands" do
  it "calls subcommand" do
    output = `foo generate model`
    expect(output).to eq("generated model: {} - model_name: \n")
  end

  context "works with params" do
    it "without params" do
      output = `foo generate model`
      expect(output).to eq("generated model: {} - model_name: \n")
    end

    it "a param using space" do
      output = `foo generate model --name user`
      expect(output).to eq("generated model: {:name=>\"user\"} - model_name: \n")
    end

    it "a param using equal sign" do
      output = `foo generate model --name=user`
      expect(output).to eq("generated model: {:name=>\"user\"} - model_name: \n")
    end

    it "a param using alias" do
      output = `foo generate model -n user`
      expect(output).to eq("generated model: {:name=>\"user\"} - model_name: \n")
    end

    it "with help param" do
      output = `foo generate model --help`

command_options_help = <<-DESC
Usage:
  foo generate model

Description:
  Generate an entity

Options:
    -n, --name name                  use the name for generating the model
    -h, --help                       Show this message
DESC
      expect(output).to eq(command_options_help)
    end

    context "with required params" do
      it "only one param" do
        output = `foo generate model user`
        expect(output).to eq("generated model: {} - model_name: user\n")
      end

      it "more than one param" do
        output = `foo destroy action web users#index`
        expect(output).to eq("destroy action: {} - application_name: web - controller_name__action_name: users#index\n")
      end

      it "more than one param and with optional params" do
        output = `foo destroy action web users#index --url=/signin`
        expect(output).to eq("destroy action: {:url=>\"/signin\"} - application_name: web - controller_name__action_name: users#index\n")
      end

      it "more than required params" do
        output = `foo destroy action web users#index unexpected_param`
        expect(output).to eq("destroy action: {} - application_name: web - controller_name__action_name: users#index\n")
      end
    end
  end
end
