---
title: Commands with subcommands and params
layout: gem-single
name: dry-cli
---

There is a way to register command with arguments, options and subcommands.

This helps to implement complex nested logic.

Arguments and options can be defined for parent both commands and child commands.

^INFO
If you call a command with an argument equal to the name of the subcommand, it will call the subcommand instead of the parent command.
^
```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Account < Dry::CLI::Command
        desc 'Information about account'

        argument :format, default: "short", values: %w[long short], desc: "Output format"

        def call(**options)
          puts "Information about account in #{options.fetch(:format)} format."
        end

        class Users < Dry::CLI::Command
          desc 'Information about account users'

          def call(**_options)
            puts "Information about account users."
          end
        end
      end

      register "account", Account
      register "account users", Account::Users
    end
  end
end

Dry::CLI.new(Foo::CLI::Commands).call
```
```
$ foo account -h
Command:
  foo account

Usage:
  foo account [FORMAT] | foo account SUBCOMMAND

Description:
  Information about account

Subcommands:
  users                         	# Information about account users

Arguments:
  FORMAT              	# Output format: (long/short)

Options:
  --help, -h                      	# Print this help
```
```sh
$ foo account
# Information about account in short format.
```

```sh
$ foo account long
# Information about account in long format.
```

```sh
$ foo account users
# Information about account users.
```

