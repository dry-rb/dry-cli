---
title: Styling your output
layout: gem-single
name: dry-cli
---

`dry-cli` comes with some functions to help you style text in the terminal. The program bellow demonstrate all available styles:

```ruby
#!/usr/bin/env ruby
require "bundler/setup"
require "dry/cli"

module StylesDemo
  extend Dry::CLI::Registry

  class Print < Dry::CLI::Command
    desc "Demonstrate all available styles"

    # rubocop:disable Metrics/AbcSize
    def call
      demo = <<~DEMO
        `bold`                   #{bold("This is bold")}
        `dim`                    #{dim("This is dim")}
        `italic`                 #{italic("This is italic")}
        `underline`              #{underline("This is underline")}
        `blink`                  #{blink("This blinks")}
        `reverse`                #{reverse("This was reversed")}
        `invisible`              #{invisible("This is invisible")} (you can't see it, right?)
        `black`                  #{black("This is black")}
        `red`                    #{red("This is red")}
        `green`                  #{green("This is green")}
        `yellow`                 #{yellow("This is yellow")}
        `blue`                   #{blue("This is blue")}
        `magenta`                #{magenta("This is magenta")}
        `cyan`                   #{cyan("This is cyan")}
        `white`                  #{white("This is white")}
        `on_black`               #{on_black("This is black")}
        `on_red`                 #{on_red("This is red")}
        `on_green`               #{on_green("This is green")}
        `on_yellow`              #{on_yellow("This is yellow")}
        `on_blue`                #{on_blue("This is blue")}
        `on_magenta`             #{on_magenta("This is magenta")}
        `on_cyan`                #{on_cyan("This is cyan")}
        `on_white`               #{on_white("This is white")}
        `bold`+`red`:            #{bold(red("This is bold red"))}
        `bold`+`on_green`:       #{bold(on_green("This is bold on green"))}
        `bold`+`red`+`on_green`: #{bold(red(on_green("This is bold red on green")))}
      DEMO
      puts demo
    end
    # rubocop:enable Metrics/AbcSize
  end

  register "print", Print
end

Dry.CLI(StylesDemo).call
```
