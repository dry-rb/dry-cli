---
title: Shell completion
layout: gem-single
name: dry-cli
---

You can add shell completion to your CLI by registering the `Dry::CLI::ShellCompletion` command:

```ruby
module Foo
  module CLI
    module Commands
      extend Dry::CLI::Registry

      # ...

      register "complete", Dry::CLI::ShellCompletion

      # ...
    end
  end
end
```

Now your users need to configure their shell of choice. For Bash users, the configuration is very simple:

```sh
complete -F get_foo_targets foo
function get_foo_targets()
{
    COMPREPLY=(`foo complete "${COMP_WORDS[@]:1}"`)
}

```

When using your CLI, `<TAB>` will trigger the completion:

```sh
$ foo s<TAB>
start stop
$ foo generate <TAB> # The completion works for subcommands too.
config test
```
