---
title: Commands
layout: gem-single
name: dry-cli
---

A command is a subclass of `Dry::CLI::Command` and it **must** respond to `#call(*)`.

For a given _command name_, you can register a corresponding _command_.

**Please note:** there is **no** convention between the _command name_ and the _command object_ class name.
The manual _registration_ assigns a _command object_ to a _command name_.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Hello < Dry::CLI::Command
        def call(*)
        end
      end
    end
  end
end

class Version < Dry::CLI::Command
  def call(*)
  end
end

Foo::CLI::Commands.register "hi", Foo::CLI::Commands::Hello
Foo::CLI::Commands.register "v",  Version

Dry::CLI.new(Foo::CLI::Commands).call
```
