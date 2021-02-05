# frozen_string_literal: true

RSpec.describe "SignalException handler" do
  it "returns correct statuscode" do
    pid1, pid2, pid15 = Array.new(3).map { Process.spawn("foo generate app SomeAppName") }
    sleep 0.5 # time to start app

    Process.kill("HUP", pid1)
    Process.kill("INT", pid2)
    Process.kill("TERM", pid15)

    _, status1 = Process.wait2(pid1)
    _, status2 = Process.wait2(pid2)
    _, status15 = Process.wait2(pid15)

    expect(status1.exitstatus).to eq(129)
    expect(status2.exitstatus).to eq(130)
    expect(status15.exitstatus).to eq(143)
  end
end
