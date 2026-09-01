# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

### Added

- Support for command namespaces (@gustavothecoder in #135)
- New `:cast` option for options and arguments, allowing to leverage Dry Types or simple procs/lambdas to cast values from string to some other type of value (@katafrakt in #157)
- Array options can be supplied by repeated flags. (@Drowze in #159)

    The following are now equivalent:
    ```
    my-cli --array-flag foo,bar
    my-cli --array-flag foo --array-flag bar
    ```
- `long_desc` method for a long command description. This will show when `--help` is given, whereas `-h` will show the short description. When no long description is provided, both `--help` and `-h` show the short description. (@aaronmallen in #160)
- `Registry#command_class` and `Registry#option`, for extending a command that another gem owns. (@afomera in #165)

    A third-party gem can now contribute the option its own hooks need, instead of that option having to be declared upfront by the gem that owns the command:

    ```ruby
    Hanami::CLI.after  "generate action", Commands::Generate::Action
    Hanami::CLI.option "generate action", :skip_tests,
                       type: :flag, default: false, desc: "Skip test generation"
    ```

    `Registry#command_class` returns the registered command's class, as an escape hatch for anything else its class-level DSL offers.

    Adding the same option twice is allowed, so independent gems can each contribute the option they need without coordinating, as long as they agree on `:type`, `:required`, `:values` and `:default`. Otherwise `Dry::CLI::IncompatibleOptionError` is raised. `:cast` is not compared, since procs aren't meaningfully comparable.
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

### Changed

- Commands and callbacks are now passed only the params their `#call` actually declares, so they no longer need a `**` catch-all to tolerate params contributed by other gems. (@afomera in #165)

    Params are passed through in full when `#call` can take them as a whole: when it declares a keyword splat or a positional. Otherwise they're matched against the keywords it declares.

- [POTENTIALLY BREAKING] `Dry::CLI::Command`'s constructor now takes three keyword arguments: `stdout:`, `stdin:`, and `:stderr`. They can be used to inject I/O stream, which is useful for testing.
- The `example` DSL now takes the example and its description as separate arguments, called once per example. Previously, examples were passed as a single array of strings with the description embedded after a `#`. (@aaronmallen and @timriley in #152)

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
  
- As with options, optional arguments can now be omitted even if list of acceptable values is defined. (@svoop in #155)

  ```ruby
  argument :required_arg, required: true, values: %w(one two)
  argument :optional_arg, required: false, values: %w(one two)
  ```

  ```
  cmd             # ERROR
  cmd one         # OKAY
  cmd three       # ERROR 
  cmd one two     # OKAY
  cmd one three   # ERROR
  ```

- Improved error messages to be more precise and helpful (@katafrakt in #158)
- Accepted values are now listed the same way in help output as in error messages, separated by commas rather than slashes. (@timriley in #163)

### Deprecated

### Removed

### Fixed

- Optional arguments were incorrectly displayed at the end of usage message (@gustavothecoder in #145)
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
- Arguments combining `type: :array` with `cast:` are now cast. Previously the cast was silently ignored for array arguments, and applied to array options only. (@timriley in #162)

  ```ruby
  argument :lines, type: :array, cast: ->(v) { Integer(v) }
  ```

  ```
  cmd 1 2  # was ["1", "2"], now [1, 2]
  ```
- An `argument` with `type: :array` is now always given to the command as an array. When the command declared more arguments than were given, it previously received no value at all. (@timriley in #162)

### Security

[Unreleased]: https://github.com/dry-rb/dry-cli/compare/v1.4.1...main

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
