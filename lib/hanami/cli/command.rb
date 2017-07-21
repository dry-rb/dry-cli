require "hanami/cli/option"
require "concurrent/array"

module Hanami
  class Cli
    class Command
      def self.inherited(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def self.extended(base)
          base.class_eval do
            @command_name = nil
            @description  = nil
            @arguments    = Concurrent::Array.new
            @options      = Concurrent::Array.new
          end
        end

        attr_reader :description
        attr_reader :arguments
        attr_accessor :command_name
      end

      def self.desc(description)
        @description = description
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
    end
  end
end
