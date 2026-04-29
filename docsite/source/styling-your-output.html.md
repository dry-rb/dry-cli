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
        `stylize("This is bold").bold`                           #=> #{stylize("This is bold").bold}
        `stylize("This is dim").dim`                             #=> #{stylize("This is dim").dim}
        `stylize("This is italic").italic`                       #=> #{stylize("This is italic").italic}
        `stylize("This is underline").underline`                 #=> #{stylize("This is underline").underline}
        `stylize("This blinks").blink`                           #=> #{stylize("This blinks").blink}
        `stylize("This was reversed").reverse`                   #=> #{stylize("This was reversed").reverse}
        `stylize("This is invisible").invisible`                 #=> #{stylize("This is invisible").invisible} (you can't see it, right?)
        `stylize("This is black").black`                         #=> #{stylize("This is black").black}
        `stylize("This is red").red`                             #=> #{stylize("This is red").red}
        `stylize("This is green").green`                         #=> #{stylize("This is green").green}
        `stylize("This is yellow").yellow`                       #=> #{stylize("This is yellow").yellow}
        `stylize("This is blue").blue`                           #=> #{stylize("This is blue").blue}
        `stylize("This is magenta").magenta`                     #=> #{stylize("This is magenta").magenta}
        `stylize("This is cyan").cyan`                           #=> #{stylize("This is cyan").cyan}
        `stylize("This is white").white`                         #=> #{stylize("This is white").white}
        `stylize("This is black").on_black`                      #=> #{stylize("This is black").on_black}
        `stylize("This is red").on_red`                          #=> #{stylize("This is red").on_red}
        `stylize("This is green").on_green`                      #=> #{stylize("This is green").on_green}
        `stylize("This is yellow").on_yellow`                    #=> #{stylize("This is yellow").on_yellow}
        `stylize("This is blue").on_blue`                        #=> #{stylize("This is blue").on_blue}
        `stylize("This is magenta").on_magenta`                  #=> #{stylize("This is magenta").on_magenta}
        `stylize("This is cyan").on_cyan`                        #=> #{stylize("This is cyan").on_cyan}
        `stylize("This is white").on_white`                      #=> #{stylize("This is white").on_white}
        `stylize("This is bold red").bold.red                    #=> #{stylize("This is bold red").bold.red}
        `stylize("This is bold on green").bold.on_green`         #=> #{stylize("This is bold on green").bold.on_green}
        `stylize("This is bold red on green").bold.red.on_green` #=> #{stylize("This is bold red on green").bold.red.on_green}
      DEMO
      puts demo
    end
    # rubocop:enable Metrics/AbcSize
  end

  register "print", Print
end

Dry.CLI(StylesDemo).call
```
