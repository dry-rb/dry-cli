#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift __dir__ + '/../../lib'
require 'dry/cli'
require_relative 'shared_commands'

WithBlock = Dry::CLI.new do |cli|
  cli.register 'assets precompile', Commands::Assets::Precompile
  cli.register 'console',           Commands::Console

  cli.register 'new',     Commands::New
  cli.register 'routes',  Commands::Routes
  cli.register 'server',  Commands::Server,  aliases: ['s']
  cli.register 'version', Commands::Version, aliases: ['v', '-v', '--version']
  cli.register 'exec',    Commands::Exec

  cli.register 'hello',       Commands::Hello
  cli.register 'greeting',    Commands::Greeting
  cli.register 'sub command', Commands::Sub::Command
  cli.register 'root-command', Commands::RootCommand
  cli.register 'root-command sub-command', Commands::RootCommands::SubCommand

  cli.register 'options-with-aliases',                Commands::OptionsWithAliases
  cli.register 'variadic default',                    Commands::VariadicArguments
  cli.register 'variadic with-mandatory',             Commands::MandatoryAndVariadicArguments
  cli.register 'variadic with-mandatory-and-options', Commands::MandatoryOptionsAndVariadicArguments

  cli.register 'generate webpack', Webpack::CLI::Generate
  cli.register 'hello',            Webpack::CLI::Hello
  cli.register 'sub command',      Webpack::CLI::SubCommand
  cli.register 'callbacks',        Webpack::CLI::CallbacksCommand

  cli.register 'db' do |prefix|
    prefix.register 'apply',   Commands::DB::Apply
    prefix.register 'console', Commands::DB::Console
    prefix.register 'create',  Commands::DB::Create
    prefix.register 'drop',    Commands::DB::Drop
    prefix.register 'migrate', Commands::DB::Migrate
    prefix.register 'prepare', Commands::DB::Prepare
    prefix.register 'version', Commands::DB::Version
    prefix.register 'rollback', Commands::DB::Rollback
  end

  cli.register 'destroy', aliases: ['d'] do |prefix|
    prefix.register 'action',    Commands::Destroy::Action
    prefix.register 'app',       Commands::Destroy::App
    prefix.register 'mailer',    Commands::Destroy::Mailer
    prefix.register 'migration', Commands::Destroy::Migration
    prefix.register 'model',     Commands::Destroy::Model
  end

  cli.register 'generate', aliases: ['g'] do |prefix|
    prefix.register 'action',    Commands::Generate::Action
    prefix.register 'app',       Commands::Generate::App
    prefix.register 'mailer',    Commands::Generate::Mailer
    prefix.register 'migration', Commands::Generate::Migration
    prefix.register 'model',     Commands::Generate::Model
    prefix.register 'secret',    Commands::Generate::Secret
  end

  # we need to be sure that command will not override with nil command
  cli.register 'generate webpack', nil

  cli.before('callbacks') do |args|
    puts "before command callback #{self.class.name} #{args.inspect}"
  end

  cli.after('callbacks') do |args|
    puts "after command callback #{self.class.name} #{args.inspect}"
  end

  cli.before 'callbacks', Callbacks::BeforeClass
  cli.after 'callbacks',  Callbacks::AfterClass
  cli.before 'callbacks', Callbacks::Before.new
  cli.after 'callbacks',  Callbacks::After.new
end
