---
title: Options
layout: gem-single
name: dry-cli
---

An option is a named argument that is passed after the _command name_ **and** the arguments.

For instance, given the `foo request` command, when an user types `foo request --mode=http2`, then `--mode=http2` is considered an option.
A command can accept none or many options.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Request < Dry::CLI::Command
        option :mode, default: "http", values: %w[http http2], desc: "The request mode"

        def call(**options)
          puts "Performing a request (mode: #{options.fetch(:mode)})"
        end
      end

      register "request", Request
    end
  end
end

Dry::CLI.new(Foo::CLI::Commands).call
```

```sh
$ foo request
Performing a request (mode: http)
```

```sh
$ foo request --mode=http2
Performing a request (mode: http2)
```

```sh
$ foo request --mode=unknown
Error: "request" was called with arguments "--mode=unknown"
```
