# frozen_string_literal: true

require "dry/cli/help_renderer"

module Dry
  class CLI
    # Settings for a CLI.
    #
    # Every CLI reads the process-wide settings, {Dry::CLI.config}, unless it is given settings of
    # its own.
    #
    # @example Process-wide
    #   Dry::CLI.configure do |config|
    #     config.help.filters << MyGem::Colorize
    #   end
    #
    # @example For one CLI
    #   config = Dry::CLI.config.dup
    #   config.help.renderer = MyGem::Renderer
    #   Dry.CLI(MyApp::Commands, config:)
    #
    # @api public
    # @since x.y.z
    class Config
      # How help is rendered.
      #
      # The renderer turns a {Dry::CLI::Screen} into one with its text filled in. Each filter then
      # takes the screen the one before it returned, and returns that screen or a changed copy of
      # it. Both are anything that responds to `#call`, such as a lambda, a module or a
      # dry-transformer function, so they compose with `>>`.
      #
      # @api public
      # @since x.y.z
      class Help
        # @return [#call] the renderer, {Dry::CLI::HelpRenderer} by default
        #
        # @api public
        attr_accessor :renderer

        # @return [Array<#call>] the filters, in the order they run
        #
        # @api public
        attr_reader :filters

        # @api private
        def initialize
          @renderer = HelpRenderer
          @filters = []
        end

        # @api private
        def initialize_copy(source)
          super
          @filters = source.filters.dup
        end

        # Renders a screen and runs it through every filter.
        #
        # @param screen [Dry::CLI::Screen] a screen without text
        #
        # @return [Dry::CLI::Screen] the screen to print
        #
        # @api private
        def call(screen)
          filters.reduce(renderer.call(screen)) { |current, filter| filter.call(current) }
        end
      end

      # @return [Help] how help is rendered
      #
      # @api public
      attr_reader :help

      # @api private
      def initialize
        @help = Help.new
      end

      # @api private
      def initialize_copy(source)
        super
        @help = source.help.dup
      end
    end

    # The process-wide settings, read by every CLI not given settings of its own.
    #
    # @return [Dry::CLI::Config]
    #
    # @api public
    # @since x.y.z
    def self.config
      @config ||= Config.new
    end

    # Changes the process-wide settings.
    #
    # @yieldparam config [Dry::CLI::Config]
    #
    # @return [Dry::CLI::Config]
    #
    # @example
    #   Dry::CLI.configure do |config|
    #     config.help.filters << ->(screen) { screen.with(text: screen.text.upcase) }
    #   end
    #
    # @api public
    # @since x.y.z
    def self.configure
      yield config
      config
    end
  end
end
