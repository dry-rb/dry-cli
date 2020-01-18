---
title: Arguments
layout: gem-single
name: dry-cli
---

An argument is a token passed after the _command name_.
For instance, given the `foo greet` command, when an user types `foo greet Luca`, then `Luca` is considered an argument.
A command can accept none or many arguments.
An argument can be declared as _required_.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Greet < Dry::CLI::Command
        argument :name, required: true, desc: "The name of the person to greet"
        argument :age, desc: "The age of the person to greet"

        def call(name:, age: nil, **)
          result = "Hello, #{name}."
          result = "#{result} You are #{age} years old." unless age.nil?

          puts result
        end
      end

      register "greet", Greet
    end
  end
end

Dry::CLI.new(Foo::CLI::Commands).call
```

```sh
$ foo greet Luca
Hello, Luca.
```

```sh
$ foo greet Luca 35
Hello, Luca. You are 35 years old.
```

```sh
$ foo greet
ERROR: "foo greet" was called with no arguments
Usage: "foo greet NAME"
```

