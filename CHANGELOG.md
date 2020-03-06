## 0.6.0 2020-03-06


### Added

- [Ivan Shamatov] Ability to pass command along with registry (for a singular command case)
- [Nikita Shilnikov] [Internal] Backported ability to run gem's CI against ruby 2.3
- [Ivan Shamatov] Inline syntax for commands
- [Ivan Shamatov] Introduced stderr to any diagnostic output

### Fixed

- [John Ledbetter & Luca Guidi] Fix ruby 2.7 warnings
- [Ivan Shamatov] Fix banner, when option is a type of Array


[Compare v0.5.1...v0.6.0](https://github.com/dry-rb/dry-cli/compare/v0.5.1...v0.6.0)

## 0.5.1 2020-01-23


### Added

- [Ivan Shamatov] Anonymous Registry sintax
- [Ivan Shamatov] [Internal] Specs refactored, more unit specs added
- [Luca Guidi] [Internal] removed `dry-inflector` as runtime dependency
- [Ivan Shamatov] [Internal] Refactored Command class (command_name property removed)
- [Piotr Solnica, Luca Guidi, Nikita Shilnikov & Christian Georgii] [Internal] Adapt gem to dry-rb style

### Fixed

- [Piotr Solnica] Added missing 'set' require


[Compare v0.5.0...v0.5.1](https://github.com/dry-rb/dry-cli/compare/v0.5.0...v0.5.1)

## 0.5.0 2019-12-21


### Added

- [Ivan Shamatov, Piotr Solnica, Luca Guidi] [Internal] removed runtime and development dependency against `hanami-utils`


[Compare v0.4.0...v0.5.0](https://github.com/dry-rb/dry-cli/compare/v0.4.0...v0.5.0)

## 0.4.0 2019-12-10


### Added

- [Ivan Shamatov, Piotr Solnica, Luca Guidi] `hanami-cli` => `dry-cli`


[Compare v0.3.1...v0.4.0](https://github.com/dry-rb/dry-cli/compare/v0.3.1...v0.4.0)

## 0.3.1 2019-01-18


### Added

- [Luca Guidi] Official support for Ruby: MRI 2.6
- [Luca Guidi] Support `bundler` 2.0+


[Compare v0.3.0...v0.3.1](https://github.com/dry-rb/dry-cli/compare/v0.3.0...v0.3.1)

## 0.3.0 2018-10-24



[Compare v0.3.0.beta1...v0.3.0](https://github.com/dry-rb/dry-cli/compare/v0.3.0.beta1...v0.3.0)

## 0.3.0.beta1 2018-08-08


### Added

- [Anton Davydov & Alfonso Uceda] Introduce array type for arguments (`foo exec test spec/bookshelf/entities spec/bookshelf/repositories`)
- [Anton Davydov & Alfonso Uceda] Introduce array type for options (`foo generate config --apps=web,api`)
- [Alfonso Uceda] Introduce variadic arguments (`foo run ruby:latest -- ruby -v`)
- [Luca Guidi] Official support for JRuby 9.2.0.0

### Fixed

- [Anton Davydov] Print informative message when unknown or wrong option is passed (`"test" was called with arguments "--framework=unknown"`)


[Compare v0.2.0...v0.3.0.beta1](https://github.com/dry-rb/dry-cli/compare/v0.2.0...v0.3.0.beta1)

## 0.2.0 2018-04-11



[Compare v0.2.0.rc2...v0.2.0](https://github.com/dry-rb/dry-cli/compare/v0.2.0.rc2...v0.2.0)

## 0.2.0.rc2 2018-04-06



[Compare v0.2.0.rc1...v0.2.0.rc2](https://github.com/dry-rb/dry-cli/compare/v0.2.0.rc1...v0.2.0.rc2)

## 0.2.0.rc1 2018-03-30



[Compare v0.2.0.beta2...v0.2.0.rc1](https://github.com/dry-rb/dry-cli/compare/v0.2.0.beta2...v0.2.0.rc1)

## 0.2.0.beta2 2018-03-23


### Added

- [Anton Davydov & Luca Guidi] Support objects as callbacks

### Fixed

- [Anton Davydov & Luca Guidi] Ensure callbacks' context of execution (aka `self`) to be the command that is being executed


[Compare v0.2.0.beta1...v0.2.0.beta2](https://github.com/dry-rb/dry-cli/compare/v0.2.0.beta1...v0.2.0.beta2)

## 0.2.0.beta1 2018-02-28


### Added

- [Anton Davydov] Register `before`/`after` callbacks for commands


[Compare v0.1.1...v0.2.0.beta1](https://github.com/dry-rb/dry-cli/compare/v0.1.1...v0.2.0.beta1)

## 0.1.1 2018-02-27


### Added

- [Luca Guidi] Official support for Ruby: MRI 2.5

### Fixed

- [Alfonso Uceda] Ensure default values for arguments to be sent to commands
- [Alfonso Uceda] Ensure to fail when a missing required argument isn't provider, but an option is provided instead


[Compare v0.1.0...v0.1.1](https://github.com/dry-rb/dry-cli/compare/v0.1.0...v0.1.1)

## 0.1.0 2017-10-25



[Compare v0.1.0.rc1...v0.1.0](https://github.com/dry-rb/dry-cli/compare/v0.1.0.rc1...v0.1.0)

## 0.1.0.rc1 2017-10-16



[Compare v0.1.0.beta3...v0.1.0.rc1](https://github.com/dry-rb/dry-cli/compare/v0.1.0.beta3...v0.1.0.rc1)

## 0.1.0.beta3 2017-10-04



[Compare v0.1.0.beta2...v0.1.0.beta3](https://github.com/dry-rb/dry-cli/compare/v0.1.0.beta2...v0.1.0.beta3)

## 0.1.0.beta2 2017-10-03


### Added

-  [Alfonso Uceda] Allow default value for arguments


[Compare v0.1.0.beta1...v0.1.0.beta2](https://github.com/dry-rb/dry-cli/compare/v0.1.0.beta1...v0.1.0.beta2)

## 0.1.0.beta1 2017-08-11


### Added

-  [Alfonso Uceda, Luca Guidi] Commands banner and usage
-  [Alfonso Uceda] Added support for subcommands
- [Alfonso Uceda] Validations for arguments and options
- [Alfonso Uceda] Commands arguments and options
- [Alfonso Uceda] Commands description
- [Alfonso Uceda, Oana Sipos] Commands aliases
- [Luca Guidi] Exit on unknown command
- [Luca Guidi, Alfonso Uceda, Oana Sipos] Command lookup
- [Luca Guidi, Tim Riley] Trie based registry to register commands and allow third-parties to override/add commands
