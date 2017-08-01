require "forwardable"
require "hanami/cli/option"
require "concurrent/array"

module Hanami
  class CLI
    class Command
      def self.inherited(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def self.extended(base)
          base.class_eval do
            @description  = nil
            @examples     = Concurrent::Array.new
            @arguments    = Concurrent::Array.new
            @options      = Concurrent::Array.new
          end
        end

        attr_reader :description
        attr_reader :examples
        attr_reader :arguments
        attr_reader :options
      end

      def self.desc(description)
        @description = description
      end

      def self.example(*examples)
        @examples += examples.flatten
      end

      def self.argument(name, options = {})
        @arguments << Argument.new(name, options)
      end

      def self.option(name, options = {})
        @options << Option.new(name, options)
      end

      def self.params
        (@arguments + @options).uniq
      end

      def self.default_params
        params.each_with_object({}) do |param, result|
          result[param.name] = param.default unless param.default.nil?
        end
      end

      def self.required_arguments
        arguments.select(&:required?)
      end

      def self.optional_arguments
        arguments.reject(&:required?)
      end

      extend Forwardable

      delegate [
        :description,
        :examples,
        :arguments,
        :options,
        :params,
        :default_params,
        :required_arguments,
        :optional_arguments,
      ] => "self.class"

      attr_reader :command_name

      def initialize(command_name:, **)
        @command_name = command_name
      end
    end
  end
end
