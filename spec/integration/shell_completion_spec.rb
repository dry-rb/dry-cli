# frozen_string_literal: true

require "open3"

RSpec.describe "Shell completion" do
  it "returns all available commands when no prefix are provided" do
    out, = Open3.capture3("foo -c")

    expected = <<~DESC
      -c
      assets
      console
      db
      destroy
      generate
      new
      routes
      server
      version
      completion
      exec
      hello
      greeting
      sub
      root-command
      variadic
      callbacks
      d
      g
      s
      v
      -v
      --version
    DESC
    expect(out).to eq(expected)
  end

  it "returns all available commands that matches the provided prefix" do
    out, = Open3.capture3("foo -c -")

    expected = <<~DESC
      -c
      -v
      --version
    DESC
    expect(out).to eq(expected)
  end

  it "returns nothing when the command is found" do
    out, = Open3.capture3("foo -c console")

    expected = <<~DESC

    DESC
    expect(out).to eq(expected)
  end

  it "returns all subcommands when command is found but no prefix are provided" do
    out, = Open3.capture3("foo -c db")

    expected = <<~DESC
      apply
      console
      create
      drop
      migrate
      prepare
      version
      rollback
    DESC
    expect(out).to eq(expected)
  end

  it "returns all subcommands that matches the provided prefix" do
    out, = Open3.capture3("foo -c db c")

    expected = <<~DESC
      console
      create
    DESC
    expect(out).to eq(expected)
  end

  it "returns nothing when subcommand is found" do
    out, = Open3.capture3("foo -c db create")

    expected = <<~DESC

    DESC
    expect(out).to eq(expected)
  end
end
