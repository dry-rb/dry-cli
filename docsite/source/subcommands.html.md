---
title: Subcommands
layout: gem-single
name: dry-cli
---

There is nothing special about subcommands, they are simply _command objects_ registered under a **nested** _command name_:

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      module Generate
        class Configuration < Dry::CLI::Command
          def call(*)
          end
        end
      end
    end
  end
end

Foo::CLI::Commands.register "generate configuration", Foo::CLI::Commands::Generate::Configuration

Dry::CLI.new(Foo::CLI::Commands).call
```

```sh
$ foo generate
Commands:
  foo generate config           # Generate configuration
```
