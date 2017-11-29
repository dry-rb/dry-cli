# Hanami::CLI

General purpose Command Line Interface (CLI) framework for Ruby.

:warning: **This is a general framework for Ruby (aka `thor` gem replacement), NOT the implementation of the `hanami` CLI commands** :warning:

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Features](#features)
    - [Registration](#registration)
    - [Commands as objects](#commands-as-objects)
    - [Subcommands](#subcommands)
    - [Arguments](#arguments)
    - [Option](#option)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Available commands](#available-commands)
    - [Help](#help)
    - [Optional arguments](#optional-arguments)
    - [Required arguments](#required-arguments)
    - [Options](#options)
    - [Boolean options](#boolean-options)
    - [Subcommands](#subcommands-1)
    - [Aliases](#aliases)
    - [Subcommand aliases](#subcommand-aliases)
  - [Development](#development)
  - [Contributing](#contributing)
  - [Alternatives](#alternatives)
  - [Copyright](#copyright)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

## Features

### Registration

For a given _command name_, you can register a corresponding _command object_ (aka command).

Example: for `foo hi` _command name_ there is the corresponding `Foo::CLI::Hello` _command object_.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "hanami/cli"

module Foo
  module CLI
    module Commands
      extend Hanami::CLI::Registry

      class Hello < Hanami::CLI::Command
        def call(*)
        end
      end
    end
  end
end

class Version < Hanami::CLI::Command
  def call(*)
  end
end

Foo::CLI::Commands.register "hi", Foo::CLI::Commands::Hello
Foo::CLI::Commands.register "v",  Version

Hanami::CLI.new(Foo::CLI::Commands).call
```

**Please note:** there is NOT a convention between the _command name_ and the _command object_ class.
The manual _registration_ assigns a _command object_ to a _command name_.

### Commands as objects

A command is a subclass of `Hanami::CLI::Command` and it MUST respond to `#call(*)`.

### Subcommands

There is nothing special in subcommands: they are just _command objects_ registered under a **nested** _command name_.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "hanami/cli"

module Foo
  module CLI
    module Commands
      extend Hanami::CLI::Registry

      module Generate
        class Configuration < Hanami::CLI::Command
          def call(*)
          end
        end
      end
    end
  end
end

Foo::CLI::Commands.register "generate configuration", Foo::CLI::Commands::Generate::Configuration

Hanami::CLI.new(Foo::CLI::Commands).call
```

### Arguments

An argument is a token passed after the _command name_.
For instance, given the `foo greet` command, when an user types `foo greet Luca`, then `Luca` is considered an argument.
A command can accept none or many arguments.
An argument can be declared as _required_.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "hanami/cli"

module Foo
  module CLI
    module Commands
      extend Hanami::CLI::Registry

      class Greet < Hanami::CLI::Command
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

Hanami::CLI.new(Foo::CLI::Commands).call
```

```shell
% foo greet Luca
Hello, Luca.
```

```shell
% foo greet Luca 35
Hello, Luca. You are 35 years old.
```

```shell
% foo greet
ERROR: "foo greet" was called with no arguments
Usage: "foo greet NAME"
```

### Option

An option is a named argument that is passed after the _command name_ **and** the arguments.

For instance, given the `foo request` command, when an user types `foo request --mode=http2`, then `--mode=http2` is considered an option.
A command can accept none or many options.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "hanami/cli"

module Foo
  module CLI
    module Commands
      extend Hanami::CLI::Registry

      class Request < Hanami::CLI::Command
        option :mode, default: "http", values: %w[http http2], desc: "The request mode"

        def call(**options)
          puts "Performing a request (mode: #{options.fetch(:mode)})"
        end
      end

      register "request", Request
    end
  end
end

Hanami::CLI.new(Foo::CLI::Commands).call
```

```shell
% foo request
Performing a request (mode: http)
```

```shell
% foo request --mode=http2
Performing a request (mode: http2)
```

```shell
% foo request --mode=unknown
Error: Invalid param provided
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "hanami-cli"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hanami-cli

## Usage

Imagine to build a CLI executable `foo` for your Ruby project.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "hanami/cli"

module Foo
  module CLI
    module Commands
      extend Hanami::CLI::Registry

      class Version < Hanami::CLI::Command
        desc "Print version"

        def call(*)
          puts "1.0.0"
        end
      end

      class Echo < Hanami::CLI::Command
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

      class Start < Hanami::CLI::Command
        desc "Start Foo machinery"

        argument :root, required: true, desc: "Root directory"

        example [
          "path/to/root # Start Foo at root directory"
        ]

        def call(root:, **)
          puts "started - root: #{root}"
        end
      end

      class Stop < Hanami::CLI::Command
        desc "Stop Foo machinery"

        option :graceful, type: :boolean, default: true, desc: "Graceful stop"

        def call(**options)
          puts "stopped - graceful: #{options.fetch(:graceful)}"
        end
      end

      module Generate
        class Configuration < Hanami::CLI::Command
          desc "Generate configuration"

          def call(*)
            puts "generated configuration"
          end
        end

        class Test < Hanami::CLI::Command
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

      register "generate", aliases: ["g"] do |prefix|
        prefix.register "config", Generate::Configuration
        prefix.register "test",   Generate::Test
      end
    end
  end
end

Hanami::CLI.new(Foo::CLI::Commands).call
```

Let's have a look at the command line usage.

### Available commands

```shell
% foo
Commands:
  foo echo [INPUT]                       # Print input
  foo generate [SUBCOMMAND]
  foo start ROOT                         # Start Foo machinery
  foo stop                               # Stop Foo machinery
  foo version                            # Print version
```

### Help

```shell
% foo echo --help
Command:
  foo echo

Usage:
  foo echo [INPUT]

Description:
  Print input

Arguments:
  INPUT               	# Input to print

Options:
  --help, -h                      	# Print this help

Examples:
  foo echo              # Prints 'wuh?'
  foo echo hello, folks # Prints 'hello, folks'
```

### Optional arguments

```shell
% foo echo
wuh?

% foo echo hello
hello
```

### Required arguments

```shell
% foo start .
started - root: .
```

```shell
% foo start
ERROR: "foo start" was called with no arguments
Usage: "foo start ROOT"
```

### Options

```shell
% foo generate test
generated tests - framework: minitest
```

```shell
% foo generate test --framework=rspec
generated tests - framework: rspec
```

```shell
% foo generate test --framework=unknown
Error: Invalid param provided
```

### Boolean options

```shell
% foo stop
stopped - graceful: true
```

```shell
% foo stop --no-graceful
stopped - graceful: false
```

### Subcommands

```shell
% foo generate
Commands:
  foo generate config           # Generate configuration
  foo generate test             # Generate tests
```

### Aliases

```shell
% foo version
1.0.0
```

```shell
% foo v
1.0.0
```

```shell
% foo -v
1.0.0
```

```shell
% foo --version
1.0.0
```

### Subcommand aliases

```shell
% foo g config
generated configuration
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hanami/cli.

## Alternatives

  * [thor](http://whatisthor.com/)
  * [clamp](https://github.com/mdub/clamp)

## Copyright

Copyright © 2017 Luca Guidi – Released under MIT License
