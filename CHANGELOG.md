# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Break Versioning](https://www.taoensso.com/break-versioning).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

[Unreleased]: https://github.com/dry-rb/dry-cli/compare/v1.4.0...main

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
