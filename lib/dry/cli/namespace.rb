# frozen_string_literal: true

module Dry
  class CLI
    # Base class for namespaces
    #
    # @since 1.1.1
    class Namespace
      # @since 1.1.1
      # @api private
      def self.inherited(base)
        super
        base.class_eval do
          @description  = nil
          @examples     = []
          @arguments    = []
          @options      = []
          @subcommands  = []
        end
        base.extend ClassMethods
      end

      # @since 1.1.1
      # @api private
      module ClassMethods
        # @since 1.1.1
        # @api private
        attr_reader :description

        # @since 1.1.1
        # @api private
        attr_reader :examples

        # @since 1.1.1
        # @api private
        attr_reader :arguments

        # @since 1.1.1
        # @api private
        attr_reader :options

        # @since 1.1.1
        # @api private
        attr_accessor :subcommands
      end

      # Set the description of the namespace
      #
      # @param description [String] the description
      #
      # @since 1.1.1
      #
      # @example
      #   require "dry/cli"
      #
      #   class YourNamespace < Dry::CLI::Namespace
      #     desc "Collection of really useful commands"
      #
      #     class YourCommand < Dry::CLI::Command
      #       # ...
      #     end
      #   end
      def self.desc(description)
        @description = description
      end

      # @since 1.1.1
      # @api private
      def self.default_params
        {}
      end

      # @since 1.1.1
      # @api private
      def self.required_arguments
        []
      end

      # @since 1.1.1
      # @api private
      def self.subcommands
        subcommands
      end
    end
  end
end
