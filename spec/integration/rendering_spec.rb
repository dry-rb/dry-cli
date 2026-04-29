# frozen_string_literal: true

require "open3"

RSpec.describe "Rendering" do
  it "prints available commands for unknown command" do
    _, stderr, = Open3.capture3("foo unknown")

    expected = <<~DESC
      Commands:
        foo assets [SUBCOMMAND]
        foo callbacks DIR                                          # Command with callbacks
        foo console                                                # Starts Foo console
        foo db [SUBCOMMAND]
        foo destroy [SUBCOMMAND]
        foo exec TASK DIRS                                         # Execute a task
        foo generate [SUBCOMMAND]
        foo greeting [RESPONSE]
        foo hello                                                  # Print a greeting
        foo nested [SUBCOMMAND]
        foo new PROJECT                                            # Generate a new Foo project
        foo root-command [ARGUMENT|SUBCOMMAND]                     # Root command with arguments and subcommands
        foo routes                                                 # Print routes
        foo server                                                 # Start Foo server (only for development)
        foo sub [SUBCOMMAND]
        foo variadic [SUBCOMMAND]
        foo version                                                # Print Foo version
    DESC

    expect(stderr).to eq(expected)
  end

  it "prints styled text" do
    stdout, = Open3.capture3("styles print")

    expected = <<~OUT
      `stylize(\"This is bold\").bold`                           #=> \e[1mThis is bold\e[0m
      `stylize(\"This is dim\").dim`                             #=> \e[2mThis is dim\e[0m
      `stylize(\"This is italic\").italic`                       #=> \e[3mThis is italic\e[0m
      `stylize(\"This is underline\").underline`                 #=> \e[4mThis is underline\e[0m
      `stylize(\"This blinks\").blink`                           #=> \e[5mThis blinks\e[0m
      `stylize(\"This was reversed\").reverse`                   #=> \e[7mThis was reversed\e[0m
      `stylize(\"This is invisible\").invisible`                 #=> \e[8mThis is invisible\e[0m (you can't see it, right?)
      `stylize(\"This is black\").black`                         #=> \e[30mThis is black\e[0m
      `stylize(\"This is red\").red`                             #=> \e[31mThis is red\e[0m
      `stylize(\"This is green\").green`                         #=> \e[32mThis is green\e[0m
      `stylize(\"This is yellow\").yellow`                       #=> \e[33mThis is yellow\e[0m
      `stylize(\"This is blue\").blue`                           #=> \e[34mThis is blue\e[0m
      `stylize(\"This is magenta\").magenta`                     #=> \e[35mThis is magenta\e[0m
      `stylize(\"This is cyan\").cyan`                           #=> \e[36mThis is cyan\e[0m
      `stylize(\"This is white\").white`                         #=> \e[37mThis is white\e[0m
      `stylize(\"This is black\").on_black`                      #=> \e[40mThis is black\e[0m
      `stylize(\"This is red\").on_red`                          #=> \e[41mThis is red\e[0m
      `stylize(\"This is green\").on_green`                      #=> \e[42mThis is green\e[0m
      `stylize(\"This is yellow\").on_yellow`                    #=> \e[43mThis is yellow\e[0m
      `stylize(\"This is blue\").on_blue`                        #=> \e[44mThis is blue\e[0m
      `stylize(\"This is magenta\").on_magenta`                  #=> \e[45mThis is magenta\e[0m
      `stylize(\"This is cyan\").on_cyan`                        #=> \e[46mThis is cyan\e[0m
      `stylize(\"This is white\").on_white`                      #=> \e[47mThis is white\e[0m
      `stylize(\"This is bold red\").bold.red                    #=> \e[31m\e[1mThis is bold red\e[0m
      `stylize(\"This is bold on green\").bold.on_green`         #=> \e[42m\e[1mThis is bold on green\e[0m
      `stylize(\"This is bold red on green\").bold.red.on_green` #=> \e[42m\e[31m\e[1mThis is bold red on green\e[0m
    OUT
    expect(stdout).to eq(expected)
  end
end
