require "hanami/cli/param"
require "optparse"

module Hanami
  module Cli
    module Command
      def self.included(base)
        base.include InstanceMethods
        base.extend ClassMethods
      end

      module InstanceMethods
        attr_reader :options, :name

        def initialize(name, options = {})
          @name = name
          @params = options[:params].to_a
          @arguments = options[:arguments]
          @desc = options[:desc]
          parse_params unless name.nil? || name.empty?
        end

        private

        def parse_params
          return unless @params

          @options = {}
          OptionParser.new do |opts|
            opts.banner = "Usage:"
            opts.separator("  #{Pathname.new($PROGRAM_NAME).basename} #{name}")
            opts.separator("")

            if @desc
              opts.separator("Description:")
              opts.separator("  #{@desc}")
              opts.separator("")
            end

            opts.separator("Options:")

            @params.each do |param|
              opts.on(*param.option_parser_options) do |value|
                @options[param.name.to_sym] = value
              end
            end

            opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit
            end
          end.parse!(@arguments)
        rescue OptionParser::InvalidOption
        end
      end

      module ClassMethods
        def desc(description)
          Hanami::Cli.add_option(self, desc: description)
        end

        def aliases(*names)
          Hanami::Cli.add_option(self, aliases: names)
        end

        def param(name, options = {})
          param = Param.new(name, options)
          Hanami::Cli.add_param(self, param)
        end

        def register(*names)
          names.each do |name|
            Hanami::Cli.register(name, self)
          end
        end
      end
    end
  end
end
