RSpec.describe "Commands" do
  it "exit with standard 0 error code" do
    `foo exit_code valid`

    expect($?.exitstatus).to eq(0)
  end

  it "exit with 1 error code when fail" do
    `foo exit_code invalid`

    expect($?.exitstatus).to eq(1)
  end
end
