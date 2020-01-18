---
title: Variadic arguments
layout: gem-single
name: dry-cli
---

Sometimes we need extra arguments because those will be forwarded to a sub-command like `ssh`, `docker` or `cat`.

By using `--` (double dash, aka hypen), the user indicates the end of the arguments and options belonging to the main command, and the beginning of the variadic arguments that can be forwarded to the sub-command.
These extra arguments are included as `:args` in the keyword arguments available for each command.

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Runner < Dry::CLI::Command
        argument :image, required: true, desc: "Docker image"

        def call(image:, args: [], **)
          puts `docker run -it --rm #{image} #{args.join(" ")}`
        end
      end

      register "run", Runner
    end
  end
end

Dry::CLI.new(Foo::CLI::Commands).call
```

```sh
$ foo run ruby:latest -- ruby -v
ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]
```

The user separates via `--` the arguments for `foo` and the command has to be run by the Docker container.
In this specific case, `ruby:latest` corresponds to the `image` mandatory argument for `foo`, whereas `ruby -v` is the variadic argument that is passed to Docker via `args`.

