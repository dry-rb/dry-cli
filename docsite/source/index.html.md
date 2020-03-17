---
title: Introduction
description: General purpose Command Line Interface (CLI) framework
layout: gem-single
type: gem
name: dry-cli
sections:
  - commands
  - subcommands
  - arguments
  - options
  - variadic-arguments
  - commands-with-subcommands-and-params
  - callbacks
  - file-utilities
---

`dry-cli` is a general-purpose framework for developing Command Line Interface (CLI) applications. It represents commands as objects that can be registered and offers support for arguments, options and forwarding variadic arguments to a sub-command.

## Usage

The following is an elaborate example showcasing most of the available features.

Imagine you want to build a CLI executable `foo` for your Ruby project. The entire program is defined as below:

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Version < Dry::CLI::Command
        desc "Print version"

        def call(*)
          puts "1.0.0"
        end
      end

      class Echo < Dry::CLI::Command
        desc "Print input"

        argument :input, desc: "Input to print"

        example [
          "             # Prints 'wuh?'",
          "hello, folks # Prints 'hello, folks'"
        ]

        def call(input: nil, **)
          if input.nil?
            puts "wuh?"
          else
            puts input
          end
        end
      end

      class Start < Dry::CLI::Command
        desc "Start Foo machinery"

        argument :root, required: true, desc: "Root directory"

        example [
          "path/to/root # Start Foo at root directory"
        ]

        def call(root:, **)
          puts "started - root: #{root}"
        end
      end

      class Stop < Dry::CLI::Command
        desc "Stop Foo machinery"

        option :graceful, type: :boolean, default: true, desc: "Graceful stop"

        def call(**options)
          puts "stopped - graceful: #{options.fetch(:graceful)}"
        end
      end

      class Exec < Dry::CLI::Command
        desc "Execute a task"

        argument :task, type: :string, required: true,  desc: "Task to be executed"
        argument :dirs, type: :array,  required: false, desc: "Optional directories"

        def call(task:, dirs: [], **)
          puts "exec - task: #{task}, dirs: #{dirs.inspect}"
        end
      end

      module Generate
        class Configuration < Dry::CLI::Command
          desc "Generate configuration"

          option :apps, type: :array, default: [], desc: "Generate configuration for specific apps"

          def call(apps:, **)
            puts "generated configuration for apps: #{apps.inspect}"
          end
        end

        class Test < Dry::CLI::Command
          desc "Generate tests"

          option :framework, default: "minitest", values: %w[minitest rspec]

          def call(framework:, **)
            puts "generated tests - framework: #{framework}"
          end
        end
      end

      register "version", Version, aliases: ["v", "-v", "--version"]
      register "echo",    Echo
      register "start",   Start
      register "stop",    Stop
      register "exec",    Exec

      register "generate", aliases: ["g"] do |prefix|
        prefix.register "config", Generate::Configuration
        prefix.register "test",   Generate::Test
      end
    end
  end
end

Dry::CLI.new(Foo::CLI::Commands).call
```

### Available commands

With this code in place, we can now have a look at the command line usage by issuing the command `foo` without any arguments or options:

```sh
$ foo
Commands:
  foo echo [INPUT]                       # Print input
  foo exec TASK [DIRS]                   # Execute a task
  foo generate [SUBCOMMAND]
  foo start ROOT                         # Start Foo machinery
  foo stop                               # Stop Foo machinery
  foo version                            # Print version
```

### Help

It is also possible to get help for a particular command using the `--help` flag:

```sh
$ foo echo --help
Command:
  foo echo

Usage:
  foo echo [INPUT]

Description:
  Print input

Arguments:
  INPUT                 # Input to print

Options:
  --help, -h                        # Print this help

Examples:
  foo echo              # Prints 'wuh?'
  foo echo hello, folks # Prints 'hello, folks'
```

### Optional arguments

A command can have optional arguments, which enables a default action in case nothing is provided:

```sh
$ foo echo
wuh?

$ foo echo hello
hello
```

### Required arguments

On the other hand, required arguments will throw an error if not provided:

```sh
$ foo start .
started - root: .
```

```sh
$ foo start
ERROR: "foo start" was called with no arguments
Usage: "foo start ROOT"
```

### Array arguments

Captures all the remaining arguments in a single array.
Please note that `array` argument must be used as the last argument, as it works as a _"catch-all"_.

```sh
$ foo exec test
exec - task: test, dirs: []
```

```sh
$ foo exec test spec/bookshelf/entities spec/bookshelf/repositories
exec - task: test, dirs: ["spec/bookshelf/entities", "spec/bookshelf/repositories"]
```

### Options

An option is a named argument that is passed after the command name and the arguments:

```sh
$ foo generate test
generated tests - framework: minitest
```

```sh
$ foo generate test --framework=rspec
generated tests - framework: rspec
```

```sh
$ foo generate test --framework=unknown
ERROR: "foo generate test" was called with arguments "--framework=unknown"
```

### Boolean options

Boolean options are flags that change the behaviour of a command:

```sh
$ foo stop
stopped - graceful: true
```

```sh
$ foo stop --no-graceful
stopped - graceful: false
```

### Array options

Array options are similar to arguments but must be named:

```sh
$ foo generate config --apps=web,api
generated configuration for apps: ["web", "api"]
```

### Subcommands

Subcommands are simply commands that have been registered under a nested path:

```sh
$ foo generate
Commands:
  foo generate config           # Generate configuration
  foo generate test             # Generate tests
```

### Aliases

Aliases are supported:

```sh
$ foo version
1.0.0
```

```sh
$ foo v
1.0.0
```

```sh
$ foo -v
1.0.0
```

```sh
$ foo --version
1.0.0
```

### Subcommand aliases

Work similarly to command aliases
```sh
$ foo g config
generated configuration for apps: []
```
