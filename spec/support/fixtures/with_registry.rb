# frozen_string_literal: true

$LOAD_PATH.unshift __dir__ + "/../../lib"
require "dry/cli"
require_relative "shared_commands"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "assets precompile", ::Commands::Assets::Precompile
      register "console",           ::Commands::Console
      register "db" do |prefix|
        prefix.register "apply",   ::Commands::DB::Apply
        prefix.register "console", ::Commands::DB::Console
        prefix.register "create",  ::Commands::DB::Create
        prefix.register "drop",    ::Commands::DB::Drop
        prefix.register "migrate", ::Commands::DB::Migrate
        prefix.register "prepare", ::Commands::DB::Prepare
        prefix.register "version", ::Commands::DB::Version
        prefix.register "rollback", ::Commands::DB::Rollback
      end

      register "destroy", aliases: ["d"] do |prefix|
        prefix.register "action",    ::Commands::Destroy::Action
        prefix.register "app",       ::Commands::Destroy::App
        prefix.register "mailer",    ::Commands::Destroy::Mailer
        prefix.register "migration", ::Commands::Destroy::Migration
        prefix.register "model",     ::Commands::Destroy::Model
      end

      register "generate", aliases: ["g"] do |prefix|
        prefix.register "action",    ::Commands::Generate::Action
        prefix.register "app",       ::Commands::Generate::App
        prefix.register "mailer",    ::Commands::Generate::Mailer
        prefix.register "migration", ::Commands::Generate::Migration
        prefix.register "model",     ::Commands::Generate::Model
        prefix.register "secret",    ::Commands::Generate::Secret
      end

      register "new",     ::Commands::New
      register "routes",  ::Commands::Routes
      register "server",  ::Commands::Server,  aliases: ["s"]
      register "version", ::Commands::Version, aliases: ["v", "-v", "--version"]
      register "exec",    ::Commands::Exec

      register "hello",       ::Commands::Hello
      register "greeting",    ::Commands::Greeting
      register "sub command", ::Commands::Sub::Command
      register "with-initializer", ::Commands::InitializedCommand.new(prop: "prop_val")
      register "root-command", ::Commands::RootCommand
      register "root-command sub-command", ::Commands::RootCommands::SubCommand

      register "options-with-aliases",                ::Commands::OptionsWithAliases
      register "variadic default",                    ::Commands::VariadicArguments
      register "variadic with-mandatory",             ::Commands::MandatoryAndVariadicArguments
      register "variadic with-mandatory-and-options", ::Commands::MandatoryOptionsAndVariadicArguments # rubocop:disable Metrics/LineLength

      register "generate webpack", ::Webpack::CLI::Generate
      register "hello",            ::Webpack::CLI::Hello
      register "sub command",      ::Webpack::CLI::SubCommand
      register "callbacks",        ::Webpack::CLI::CallbacksCommand

      register "generate webpack", nil

      before("callbacks") do |args|
        puts "before command callback #{self.class.name} #{args.inspect}"
      end

      after("callbacks") do |args|
        puts "after command callback #{self.class.name} #{args.inspect}"
      end

      before("callbacks", ::Callbacks::BeforeClass)
      after("callbacks",  ::Callbacks::AfterClass)
      before("callbacks", ::Callbacks::Before.new)
      after("callbacks",  ::Callbacks::After.new)
    end
  end
end

WithRegistry = Dry::CLI.new(Foo::CLI::Commands)
