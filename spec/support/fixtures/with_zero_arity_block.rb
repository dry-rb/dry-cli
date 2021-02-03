#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift __dir__ + "/../../lib"
require "dry/cli"
require_relative "shared_commands"

WithZeroArityBlock = Dry.CLI do
  register "assets precompile", Commands::Assets::Precompile
  register "console",           Commands::Console

  register "new",     Commands::New
  register "routes",  Commands::Routes
  register "server",  Commands::Server,  aliases: ["s"]
  register "version", Commands::Version, aliases: ["v", "-v", "--version"]
  register "exec",    Commands::Exec

  register "hello",       Commands::Hello
  register "greeting",    Commands::Greeting
  register "sub command", Commands::Sub::Command
  register "with-initializer", Commands::InitializedCommand.new(prop: "prop_val")
  register "root-command", Commands::RootCommand
  register "root-command" do
    register "sub-command", Commands::RootCommands::SubCommand
  end

  register "options-with-aliases",                Commands::OptionsWithAliases
  register "variadic default",                    Commands::VariadicArguments
  register "variadic with-mandatory",             Commands::MandatoryAndVariadicArguments
  register "variadic with-mandatory-and-options", Commands::MandatoryOptionsAndVariadicArguments

  register "generate webpack", Webpack::CLI::Generate
  register "hello",            Webpack::CLI::Hello
  register "sub command",      Webpack::CLI::SubCommand
  register "callbacks",        Webpack::CLI::CallbacksCommand

  register "db" do
    register "apply",   Commands::DB::Apply
    register "console", Commands::DB::Console
    register "create",  Commands::DB::Create
    register "drop",    Commands::DB::Drop
    register "migrate", Commands::DB::Migrate
    register "prepare", Commands::DB::Prepare
    register "version", Commands::DB::Version
    register "rollback", Commands::DB::Rollback
  end

  register "destroy", aliases: ["d"] do
    register "action",    Commands::Destroy::Action
    register "app",       Commands::Destroy::App
    register "mailer",    Commands::Destroy::Mailer
    register "migration", Commands::Destroy::Migration
    register "model",     Commands::Destroy::Model
  end

  register "generate", aliases: ["g"] do
    register "action",    Commands::Generate::Action
    register "app",       Commands::Generate::App
    register "mailer",    Commands::Generate::Mailer
    register "migration", Commands::Generate::Migration
    register "model",     Commands::Generate::Model
    register "secret",    Commands::Generate::Secret
  end

  register "inherited", aliases: ["i"] do
    register "run",    InheritedCommands::Run
    register "subrun", InheritedCommands::SubRun
    register "logs",   InheritedCommands::Logs
    register "addons", InheritedCommands::Addons
  end

  # we need to be sure that command will not override with nil command
  register "generate webpack", nil

  before("callbacks") do |args|
    puts "before command callback #{self.class.name} #{args.inspect}"
  end

  after("callbacks") do |args|
    puts "after command callback #{self.class.name} #{args.inspect}"
  end

  before "callbacks", Callbacks::BeforeClass
  after "callbacks",  Callbacks::AfterClass
  before "callbacks", Callbacks::Before.new
  after "callbacks",  Callbacks::After.new
end
