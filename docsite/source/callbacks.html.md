---
title: Callbacks
layout: gem-single
name: dry-cli
---

Third party gems can register _before_ and _after_ callbacks to enhance a command.

### Example

From the `foo` gem we have a command `hello`.

```ruby
#!/usr/bin/env ruby
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Hello < Dry::CLI::Command
        argument :name, required: true

        def call(name:, **)
          puts "hello #{name}"
        end
      end
    end
  end
end

Foo::CLI::Commands.register "hello", Foo::CLI::Commands::Hello

cli = Dry::CLI.new(Foo::CLI::Commands)
cli.call
```

The `foo-bar` gem enhances `hello` command with callbacks:

```ruby
Foo::CLI::Commands.before("hello") { |args| puts "debug: #{args.inspect}" } # syntax 1
Foo::CLI::Commands.after "hello", &->(args) { puts "bye, #{args.fetch(:name)}" } # syntax 2
```

```sh
$ foo hello Anton
debug: {:name=>"Anton"}
hello Anton
bye, Anton
```
