# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

[Unreleased]: https://github.com/dry-rb/dry-cli/compare/v1.4.1...main

## [2.0.0.rc1] - 2026-11-19

### Added

- Support for command namespaces. (@gustavothecoder in #135)

    Subclass `Dry::CLI::Namespace` to group commands under a name that is not a command itself:

    ```ruby
    class DB < Dry::CLI::Namespace
      desc "Manage the database"
    end

    register "db", DB
    register "db migrate", DB::Migrate
    register "db rollback", DB::Rollback
    ```

    Running `my-cli db` lists the commands in the namespace, and `my-cli db --help` shows its help.
- A `long_desc` method for a long command descriptions. This will show when `--help` is given, whereas `-h` will show the short description. When no long description is provided, both `--help` and `-h` show the short description. (@aaronmallen in #160)

    ```ruby
    class Echo < Dry::CLI::Command
      desc "Prints given input"
      long_desc <<~DESC
        Prints the given input back to standard output.

        When no input is given, it prints an empty line.
      DESC
    end
    ```

    `Dry::CLI::Namespace` also has `long_desc`.
- A `:cast` option for options and arguments, allowing to leverage Dry Types or simple procs/lambdas to cast values from string to some other type of value. (@katafrakt in #157, @timriley in #162)

    Give `cast:` anything that responds to `#call`:

    ```ruby
    Types = Dry.Types()

    class Info < Dry::CLI::Command
      argument :lines, cast: Types::Coercible::Integer, default: 10
      option :sudo, cast: Types::Params::Bool, default: false
      option :uid, cast: ->(v) { Integer(v) }
    end
    ```

    ```
    my-cli info 15 --sudo true --uid 16  # lines: 15, sudo: true, uid: 16
    ```

    With `type: :array`, each value is cast on its own. If casting raises an error, the command does not run, and the error is printed:

    ```
    my-cli info --sudo maybe
    ERROR when casting sudo: maybe cannot be coerced to false.
    ```
- Array options can be supplied by repeated flags. (@Drowze in #159)

    The following are now equivalent:
    ```
    my-cli --array-flag foo,bar
    my-cli --array-flag foo --array-flag bar
    ```
- `Dry::CLI::Command#auto_initialize`, for taking select keywords that `.new` assigns itself, rather than passing on to `#initialize`. (@timriley in #167)

    It is common for a CLI app to set up "standard" dependencies that can be provided to every command class. Making these auto-initialized keywords keeps each command's `#initialize` focused on its own distinct dependencies, while the standard dependencies are still assigned as expected. Command class authors do not need to supply `**kwargs` as an `#initialize` parameter and then call `super(**kwargs)`, which reduces boilerplate, as well as the chance of bugs from these lines being forgotten.

    A subclass adding its own needs only to declare and assign them. Write it alongside your `#initialize`, since the two share the job of setting the command up:

    ```ruby
    # In a CLI app's base command class

    # `inflector:` becomes a standard dependency, and can also take a default value.
    private def auto_initialize(inflector: Dry::Inflector.new, **kwargs)
      super(**kwargs)
      @inflector = inflector
    end
    ```

    This makes `inflector:` work as an argument to `.new`, and assigns its value to an ivar automatically, before `#initialize` is called.

    Auto-initialized keywords are best used sparingly. Consider these for your CLI app's base command class only. A command cannot use auto-initialized keywords as their own `#initialize` parameters, since it will never receive them.
- `Dry::CLI::Command#invoke`, for running one command from within another. (@parndt in #183)

    The other command is built with the auto-initialized keywords of the command invoking it, so it writes to the same streams and shares the same standard dependencies. Its option defaults apply to any options not given (or given as nil), and it is given only the keywords its `#call` accepts, so a command can pass along all of its own options:

    ```ruby
    class Migrate < MyApp::Command
      def call(...)
        invoke(Create, ...)
        # ...
      end
    end
    ```

    When a command passes along its options like this, its option defaults are passed along too, and replace the other command's defaults for any options they share.

    Unlike running the other command from the command line, the given values are not cast to their option types or checked against `required:` or `values:`, and no `before` or `after` callbacks registered for the other command are run.

    Each auto-initialized keyword is read back through the reader of the same name, so every auto-initialized keyword needs a reader.
- `Registry#command_class` and `Registry#option`, for extending a command that another gem owns. (@afomera in #165)

    A third-party gem can now contribute the option its own hooks need, instead of that option having to be declared upfront by the gem that owns the command:

    ```ruby
    Hanami::CLI.after  "generate action", Commands::Generate::Action
    Hanami::CLI.option "generate action", :skip_tests,
                       type: :flag, default: false, desc: "Skip test generation"
    ```

    `Registry#command_class` returns the registered command's class, as an escape hatch for anything else its class-level DSL offers.

    Adding the same option twice is allowed, so independent gems can each contribute the option they need without coordinating, as long as they agree on `:type`, `:required`, `:values` and `:default`. Otherwise `Dry::CLI::CommandDefinitionError` is raised. `:cast` is not compared, since procs aren't meaningfully comparable.
- `Dry::CLI.accepted_kwargs`, which returns only the keyword args that a method or proc accepts, based on its params. Use it when you wrap a command's `#call`, to pass on only the keyword args that the next `#call` accepts. (@timriley in #181)

    ```ruby
    class Deploy < Dry::CLI::Command
      def call(target:, force: false) = ...
    end

    kwargs = {target: "production", env: "test"}

    Dry::CLI.accepted_kwargs(Deploy.new.method(:call), kwargs)
    # => {target: "production"}
    ```
- Commands and callbacks can stop the CLI with an exit code by throwing `:exit`. The CLI catches the throw and exits with the code. A bare `throw :exit` exits with 0. (@timriley in #180)

    ```ruby
    class Deploy < Dry::CLI::Command
      def call(**)
        unless File.exist?("config.yml")
          stderr.puts "config.yml not found"
          throw :exit, 1
        end

        # ...
      end
    end
    ```
- `Dry::CLI::ExitError`, for errors the user is meant to see. Raise it (or your own subclass) from anywhere in a command or callback. The CLI prints its message to stderr, with no backtrace, then exits with its `exit_code` (1 by default). Other errors are not rescued, so they keep their backtrace. (@timriley in #180)

    ```ruby
    raise Dry::CLI::ExitError, "config.yml not found"
    raise Dry::CLI::ExitError.new("deploy failed", exit_code: 2)
    ```
- `Dry::CLI#call` accepts an `exit:` argument, which the CLI calls with the exit code instead of `Kernel#exit`. With this, tests can check exit codes without stubbing `Kernel#exit` or rescuing `SystemExit`. (@timriley in #180)

    ```ruby
    exit_code = nil
    cli.call(arguments: ["deploy"], exit: ->(code) { exit_code = code })
    exit_code # => 1
    ```

    Existing commands that call `Kernel#exit` itself still exit the process directly, and do not use `exit:`. To use `exit:`, change these calls to `throw :exit, code`, or raise `Dry::CLI::ExitError`.
- Support for styled text. (@aaronmallen and @timriley in #166)

    Use `style` in your commands (or `Dry::CLI::Style`) directly to build styles, then send text to those styles. Once you pass that text to an output stream, it will be styled (and its colors gracefully degraded if required) based on the terminal's capabilities. Styled text sent to a non-terminal stream (such as when a CLI command has output redirected to a file) will not be styled.

    ```ruby
    # Dry::CLI::Command gets `style` at both the class and instance level; use Dry::CLI::StyleMixin to add this to your own classes.
    ERROR = style.bold.red

    def call
      text = ERROR["boom"]
      stderr.puts text # renders as "\e[1;31mboom\e[0m"
    end
    ```

    `Command#stdout` and `#stderr` are now always instances of `Dry::CLI::Stream`. Use `stdout.raw` to access the underlying IO object directly.
- Formatting support for styled text. (@alassek in #168)

    `Dry::CLI::Style::Text` objects have a `#%` method that behaves like `String#%` but respects the style information.

    ```ruby
    style.bold.red["%s"] % "boom" # => "\e[1;31mboom\e[0m"
    ```
- `Dry::CLI::Spinner`: a simple, animated spinner for long-running tasks. (@alassek in #169)

    Four default styles: Dot, Ellipsis, Line, MiniDot.

    The simplest case is a block to run the task and a static message to display (supports styled text):

    ```ruby
    Dry::CLI::Spinner::Dot.run("%{spinner} working...") do
      sleep 3
    end
    ```

    If you require more control, you can provide a block argument and register `before_tick` and `after_tick` callbacks:

    ```ruby
    template =  style.bold.green["%{spinner}"]
    template += style.italic.dim[" waiting "]
    template += style.bold.white["%{num}"]
    template += style.italic.dim[" seconds"]

    Dry::CLI::Spinner::MiniDot.run(template) do |s|
      trailer = Dry::CLI::Spinner::Ellipsis.frames.cycle
      start   = Time.now

      s.before_tick do |_stream, data|
        data[:num] = (Time.now - start).ceil
      end

      s.after_tick do |stream|
        stream << style.italic.dim[trailer.next]
      end

      s.run { sleep 6 }
    end
    ```

### Changed

- [BREAKING] `Dry::CLI::Command#out` and `#err` are renamed to `#stdout` and `#stderr`, and `Dry::CLI#call` takes `stdout:` and `stderr:` instead of `out:` and `err:`. (@aaronmallen in #151)

    ```ruby
    # Before
    def call
      out.puts "Deployed"
      err.puts "Warning: no changes"
    end

    cli.call(arguments: ["deploy"], out: my_out, err: my_err)

    # Now
    def call
      stdout.puts "Deployed"
      stderr.puts "Warning: no changes"
    end

    cli.call(arguments: ["deploy"], stdout: my_out, stderr: my_err)
    ```
- [BREAKING] `required: true` on options is enforced. (@capripot and @timriley in #122)

    Before, `required: true` was accepted on options but did nothing. Now, if a required option is not given, the command does not run, and prints an error that names the missing option. Required options are marked as REQUIRED in the help output. A required option with a `default:` always has a value, so it is not enforced and not marked as required.

    If your commands already declare options with `required: true` and no default, they will now fail when the user leaves those options out.

    ```ruby
    class Server < Dry::CLI::Command
      option :host, required: true, desc: "Host"
      option :port, required: true, desc: "Port"
    end
    ```

    ```
    $ my-cli server --host=localhost
    ERROR: "my-cli server" is missing required option --port
    Usage: "my-cli server --host=VALUE --port=VALUE"

    $ my-cli server --help
    ...
    Options:
      --host=VALUE  # REQUIRED Host
      --port=VALUE  # REQUIRED Port
      --help, -h    # Print this help
    ```
- [BREAKING] Declaring an argument with both `required: true` and a `default:` raises `Dry::CLI::CommandDefinitionError`. Remove either `required: true` or the default. (@timriley in #177)
- [BREAKING] Declaring a required argument after an optional one, or any argument after an array argument, raises `Dry::CLI::CommandDefinitionError`. Since arguments are matched by position, such a command could never be called correctly: a required argument could not be given without also giving the optional one before it, and an array argument takes all the remaining values, leaving none for the arguments after it. (@timriley in #177)

    ```ruby
    argument :env
    argument :name, required: true
    # => required argument `name' can't be declared after optional argument `env'

    argument :files, type: :array
    argument :dest
    # => argument `dest' can't be declared after array argument `files'
    ```
- The `example` DSL now takes the example and its description as separate arguments, called once per example. Previously, examples were passed as a single array of strings with the description embedded after a `#`. Passing an array still works, but prints a deprecation warning. This will be removed in 3.0. (@aaronmallen and @timriley in #152, #184)

  ```ruby
  class Server < Dry::CLI::Command
    # Now:
    example "--server=webrick",    "Force `webrick` server engine"
    example "--host=0.0.0.0",      "Bind to a host"
    example "--port=2306",         "Bind to a port"
    example "--no-code-reloading", "Disable code reloading"

    # Before:
    example [
      "--server=webrick    # Force `webrick` server engine",
      "--host=0.0.0.0      # Bind to a host",
      # ...
    ]
  end
  ```
- `Dry::CLI::Command.new` now takes three keyword arguments: `stdout:`, `stdin:` and `stderr:`. These can be used to inject I/O streams, which is useful for testing. (@aaronmallen in #151, @timriley in #167)

    These arguments are taken by `.new` and set on the command instance before `#initialize` runs, so `#initialize` in a subclass only needs to worry about its own arguments, with no call to `super` required:

    ```ruby
    class Generate < Dry::CLI::Command
      def initialize(generator: Generator.new)
        @generator = generator
      end
    end

    Generate.new(stdout: io, generator: generator)
    ```

    A command registered as an instance will have its streams replaced after it is built, so avoid building on top of the streams from inside `#initialize`. Instead, build from a stream lazily, only when you use it. See `Dry::CLI::Command` for details.
- Commands and callbacks are now passed only the keyword args that match the params their `#call` declares, so they no longer need a `**` catch-all param to tolerate options contributed by other gems. (@afomera in #165)

    Every keyword arg is passed when `#call` can take them as a whole: when it declares a keyword splat param or a positional param. Otherwise they're matched against the keyword params it declares.

    For example, if another gem adds a `--skip-tests` option to this command, the command still works:

    ```ruby
    class Generate < Dry::CLI::Command
      argument :name, required: true

      # Before, this raised ArgumentError (unknown keyword: :skip_tests)
      # unless it was `def call(name:, **)`
      def call(name:)
        # ...
      end
    end
    ```
- Exits for help (status 0), invalid options and arguments (1), and unknown commands (1) now go through the `exit:` given to `Dry::CLI#call`. (@timriley in #180)
- Error messages for invalid input now name the option or argument that is wrong, instead of repeating everything that was given. (@katafrakt in #158)

    ```
    $ my-cli server --unknown 1234
    # Before
    ERROR: "my-cli server" was called with arguments "--unknown 1234"
    # Now
    ERROR: "my-cli server" was called with invalid option "--unknown"

    $ my-cli db rollback 4
    # Before
    ERROR: "my-cli db rollback" was called with arguments "4"
    # Now
    ERROR: invalid argument "4" for "steps"; accepted values: 1, 2, 3
    ```

    If you match on error text (in tests, for example), you will need to update it.
- Accepted values are now listed the same way in help output as in error messages, separated by commas rather than slashes. (@timriley in #163)

    ```
    # Before
    --engine=VALUE  # Engine: (irb/pry)
    # Now
    --engine=VALUE  # Engine: (irb, pry)
    ```

### Fixed

- An `argument` with `type: :array` is now always given to the command as an array. When the command declared more arguments than were given, it previously received no value at all. (@timriley in #162)

    ```ruby
    argument :task
    argument :files, type: :array
    ```

    ```
    cmd  # was {}, now {files: []}
    ```
- A required `argument` with `type: :array` no longer has its values repeated in `args`. It takes all the remaining values, but all except the first were also given in `args`. (@parndt in #178)

  ```ruby
  argument :task, required: true
  argument :dirs, type: :array, required: true
  ```

  ```
  cmd test lib spec  # was dirs: ["lib", "spec"], args: ["spec"], now dirs: ["lib", "spec"]
  ```
- Redeclaring an argument, such as in a subclass to change its `desc`, now keeps the argument in its original position. Previously it was moved to the end, so values given on the command line were matched to the wrong arguments. (@timriley in #177)
- Show array arguments last in the usage line of help output. (@gustavothecoder in #145)
- An optional argument with `values:` can now be left out. Before, leaving it out gave an error, as if it were required. Options already worked this way. (@svoop in #155)

  ```ruby
  argument :mode, required: true, values: %w[fast slow]
  argument :level, values: %w[low high]
  ```

  ```
  cmd fast       # was an error, now {mode: "fast"}
  cmd fast high  # {mode: "fast", level: "high"}
  cmd fast max   # error: "max" is not an accepted value
  ```
- Options combining `type: :array` with `values:` no longer return a single string instead of an array, and now accept comma-separated values. (@timriley in #161)

  ```ruby
  option :require, type: :array, values: %w[foo bar baz]
  ```

  ```
  cmd --require=foo      # was "foo", now ["foo"]
  cmd --require=foo,bar  # was an error, now ["foo", "bar"]
  ```
- Allow options and arguments to specify non-string `values:`, such as integers. These are cast to strings when declared, then compared against the strings given on the command line. (@timriley in #161)

  ```ruby
  option :level, values: [1, 2, 3]
  ```

  ```
  cmd --level=1  # was an error, now "1"
  ```

[2.0.0.rc1]: https://github.com/dry-rb/dry-cli/compare/v1.4.1...v2.0.0.rc1

## [1.4.1] - 2026-01-21

### Fixed

- Remove spurious leading blank line when printing usage output. (@aaronmallen in #154)

[1.4.1]: https://github.com/dry-rb/dry-cli/compare/v1.4.0...v1.4.1

## [1.4.0] - 2026-01-09

### Added

- Provide the CLI’s `out` and `err` streams to command instances (unless `@out` and `@err` ivars  already exist in the command). (@aaronmallen in #150)

### Changed

- Require Ruby 3.2 or later. (@timriley)

### Fixed

- Pass a commands keyword arguments to any related callbacks. (@gustavothecoder in #136)
- Avoid duplicated option names in `--help` output when a subclass re-defines an option. (@gustavothecoder in #143)
- Properly raise an error when an invalid value is passed to an option (previously this was working for arguments only, not options). (@gustavothecoder in #142)

[1.4.0]: https://github.com/dry-rb/dry-cli/compare/v1.3.0...v1.4.0

## [1.3.0] - 2025-07-29

### Added

- Support unlimited nesting when registering commands via `register` with blocks. (@aaronmallen in #149)

  You could previously do this only with fully qualified registrations:

  ```ruby
  Commands.register "nested one", MyFirstNestedCommand
  Commands.register "nested one two", MySecondNestedCommand
  Commands.register "nested one two three", MyThirdNestedCommand
  ```

  Now you can do the same via blocks:

  ```ruby
  Commands.register "nested" do
    register "one", MyFirstNestedCommand do
      register "two", MySecondNestedCommand do
        register "three", MyThirdNestedCommand
      end
    end
  end
  ```

### Changed

- Set minimum Ruby version to 3.1. (@timriley)

[1.3.0]: https://github.com/dry-rb/dry-cli/compare/v1.2.0...v1.3.0

## [1.2.0] - 2024-10-15

### Added

- Added `:hidden` option to register commands that should not be shown in the help output. (@benoittgt in #137)
- Provide suggestions when there is a typo in a command name. (@benoittgt in #138)

[1.2.0]: https://github.com/dry-rb/dry-cli/compare/v1.1.0...v1.2.0

## [1.1.0] - 2024-07-14

### Added

- Added `:flag` option type. This acts like a `:boolean` that can only be set to true, so has no `--no-` prefix to disable it. (@Billiam in #117)

[1.1.0]: https://github.com/dry-rb/dry-cli/compare/v1.0.0...v1.1.0

## [1.0.0] - 2022-11-05

### Changed

- Version bumped to 1.0.0 (@solnic)

[1.0.0]: https://github.com/dry-rb/dry-cli/compare/v0.7.0...v1.0.0

## [0.7.0] - 2020-05-08

### Added

- Inheritable attributes for subclasses of commands (@IvanShamatov)
- Ability to register instances, not only classes as Commands (@IvanShamatov)
- Add support for subcommands with a parent command (@unrooty)

### Fixed

- Safely rescue pipe exception, when you CLI app is producing output for piped CLI app (IvanShamatov)
- Safely rescue keyboard interrupts (@IvanShamatov)
- [Internal] Don't run specs twice (@jodosha)
- Update inline call with keyward arguments (@flash-gordon)

### Changed

- Extracted Dry::CLI::Utils::Files into dry-files (@jodosha)
- Drop 2.3 ruby support (@IvanShamatov)
- [Internal] Changelog, issue templates (@solnic)
- Documentation updates (@davydovanton)
- Remove concurrent-ruby as runtime dependency (@jodosha)
- [Internal] Banner and Parses refactoring (@IvanShamatov)

[0.7.0]: https://github.com/dry-rb/dry-cli/compare/v0.6.0...v0.7.0

## [0.6.0] - 2020-03-06

### Added

- Ability to pass command along with registry (for a singular command case) (@IvanShamatov)
- [Internal] Backported ability to run gem's CI against ruby 2.3 (@flash-gordon)
- Inline syntax for commands (@IvanShamatov)
- Introduced stderr to any diagnostic output (@IvanShamatov)

### Fixed

- [John Ledbetter & Luca Guidi] Fix ruby 2.7 warnings (@jodosha)
- Fix banner, when option is a type of Array (@IvanShamatov)

[0.6.0]: https://github.com/dry-rb/dry-cli/compare/v0.5.1...v0.6.0

## [0.5.1] - 2020-01-23

### Added

- Anonymous Registry sintax (@IvanShamatov)
- [Internal] Specs refactored, more unit specs added (@IvanShamatov)
- [Internal] removed `dry-inflector` as runtime dependency (@jodosha)
- [Internal] Refactored Command class (command_name property removed) (@IvanShamatov)
- [Internal] Adapt gem to dry-rb style (@jodosha, @flash-gordon, @solnic, @cgeorgii)

### Fixed

- Added missing 'set' require (@solnic)

[0.5.1]: https://github.com/dry-rb/dry-cli/compare/v0.5.0...v0.5.1

## [0.5.0] - 2019-12-21

### Added

- [Internal] removed runtime and development dependency against `hanami-utils` (@jodosha, @IvanShamatov, @solnic)

[0.5.0]: https://github.com/dry-rb/dry-cli/compare/v0.4.0...v0.5.0

## [0.4.0] - 2019-12-10

### Added

- `hanami-cli` => `dry-cli` (@jodosha, @IvanShamatov, @solnic)

[0.4.0]: https://github.com/dry-rb/dry-cli/compare/v0.3.1...v0.4.0

## [0.3.1] - 2019-01-18

### Added

- Official support for Ruby: MRI 2.6 (@jodosha)
- Support `bundler` 2.0+ (@jodosha)

[0.3.1]: https://github.com/dry-rb/dry-cli/compare/v0.3.0...v0.3.1

## [0.3.0] - 2018-10-24

[0.3.0]: https://github.com/dry-rb/dry-cli/compare/v0.3.0.beta1...v0.3.0

## [0.3.0.beta1] - 2018-08-08

### Added

- Introduce array type for arguments (`foo exec test spec/bookshelf/entities spec/bookshelf/repositories`) (@davydovanton, @AlfonsoUceda)
- Introduce array type for options (`foo generate config --apps=web,api`) (@davydovanton, @AlfonsoUceda)
- Introduce variadic arguments (`foo run ruby:latest -- ruby -v`)
- Official support for JRuby 9.2.0.0 (@jodosha, @AlfonsoUceda)

### Fixed

- Print informative message when unknown or wrong option is passed (`"test" was called with arguments "--framework=unknown"`) (@davydovanton)

[0.3.0.beta1]: https://github.com/dry-rb/dry-cli/compare/v0.2.0...v0.3.0.beta1

## [0.2.0] - 2018-04-11

[0.2.0]: https://github.com/dry-rb/dry-cli/compare/v0.2.0.rc2...v0.2.0

## [0.2.0.rc2] - 2018-04-06

[0.2.0.rc2]: https://github.com/dry-rb/dry-cli/compare/v0.2.0.rc1...v0.2.0.rc2

## [0.2.0.rc1] - 2018-03-30

[0.2.0.rc1]: https://github.com/dry-rb/dry-cli/compare/v0.2.0.beta2...v0.2.0.rc1

## [0.2.0.beta2] - 2018-03-23

### Added

- Support objects as callbacks (@jodosha, @davydovanton)

### Fixed

- Ensure callbacks' context of execution (aka `self`) to be the command that is being executed (@jodosha, @davydovanton)

[0.2.0.beta2]: https://github.com/dry-rb/dry-cli/compare/v0.2.0.beta1...v0.2.0.beta2

## [0.2.0.beta1] - 2018-02-28

### Added

- Register `before`/`after` callbacks for commands (@davydovanton)

[0.2.0.beta1]: https://github.com/dry-rb/dry-cli/compare/v0.1.1...v0.2.0.beta1

## [0.1.1] - 2018-02-27

### Added

- Official support for Ruby: MRI 2.5 (@jodosha)

### Fixed

- Ensure default values for arguments to be sent to commands (@AlfonsoUceda)
- Ensure to fail when a missing required argument isn't provider, but an option is provided instead (@AlfonsoUceda)

[0.1.1]: https://github.com/dry-rb/dry-cli/compare/v0.1.0...v0.1.1

## [0.1.0] - 2017-10-25

[0.1.0]: https://github.com/dry-rb/dry-cli/compare/v0.1.0.rc1...v0.1.0

## [0.1.0.rc1] - 2017-10-16

[0.1.0.rc1]: https://github.com/dry-rb/dry-cli/compare/v0.1.0.beta3...v0.1.0.rc1

## [0.1.0.beta3] - 2017-10-04

[0.1.0.beta3]: https://github.com/dry-rb/dry-cli/compare/v0.1.0.beta2...v0.1.0.beta3

## [0.1.0.beta2] - 2017-10-03

### Added

- Allow default value for arguments (@AlfonsoUceda)

[0.1.0.beta2]: https://github.com/dry-rb/dry-cli/compare/v0.1.0.beta1...v0.1.0.beta2

## [0.1.0.beta1] - 2017-08-11

### Added

- Commands banner and usage (@jodosha, @AlfonsoUceda)
- Added support for subcommands (@AlfonsoUceda)
- Validations for arguments and options (@AlfonsoUceda)
- Commands arguments and options (@AlfonsoUceda)
- Commands description (@AlfonsoUceda)
- Commands aliases (@AlfonsoUceda, @oana-sipos)
- Exit on unknown command (@jodosha)
- Command lookup (@AlfonsoUceda, @oana-sipos)
- Trie based registry to register commands and allow third-parties to override/add commands (@jodosha, @timriley)
