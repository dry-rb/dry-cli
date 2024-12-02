---
title: Colorizing your output
layout: gem-single
name: dry-cli
---

`dry-cli` comes with some functions to help you print colored text in the terminal. The program bellow demonstrate all available functions:

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module ColorsDemo
  extend Dry::CLI::Registry

  class Print < Dry::CLI::Command
    desc "Demonstrate all available colors"

    def call
      demo = <<~DEMO
        # Style ###############################################################
        Bold: #{bold("This is bold")}
        # Foreground ##########################################################
        Black:   #{black("This is black")}
        Red:     #{red("This is red")}
        Green:   #{green("This is green")}
        Yellow:  #{yellow("This is yellow")}
        Blue:    #{blue("This is blue")}
        Magenta: #{magenta("This is magenta")}
        Cyan:    #{cyan("This is cyan")}
        White:   #{white("This is white")}
        # Background ##########################################################
        Black:   #{on_black("This is black")}
        Red:     #{on_red("This is red")}
        Green:   #{on_green("This is green")}
        Yellow:  #{on_yellow("This is yellow")}
        Blue:    #{on_blue("This is blue")}
        Magenta: #{on_magenta("This is magenta")}
        Cyan:    #{on_cyan("This is cyan")}
        White:   #{on_white("This is white")}
        # Combinations ########################################################
        Bold+Foreground:            #{bold(red("This is bold red"))}
        Bold+Background:            #{bold(on_green("This is bold on green"))}
        Bold+Foreground+Background: #{bold(red(on_green("This is bold red on green")))}
      DEMO
      puts demo
    end
  end

  register "print", Print
end

Dry.CLI(ColorsDemo).call
```
