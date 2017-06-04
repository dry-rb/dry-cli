require "hanami/cli/param"

module Hanami
  module Cli
    class Command
      attr_reader :options

      def initialize(params:, arguments:)
        @params = params
        @arguments = arguments
        parse_params
      end

      def self.desc(description)
        Hanami::Cli.add_option(self, desc: description)
      end

      def self.aliases(*names)
        Hanami::Cli.add_option(self, aliases: names)
      end

      def self.param(name, options = {})
        param = Param.new(name, options)
        Hanami::Cli.add_param(self, param)
      end

      def self.register(*names)
        names.each do |name|
          Hanami::Cli.register(name, self)
        end
      end

      private

      def parse_params
        return unless @params
        @options = {}
        OptionParser.new do |opts|
          opts.set_program_name("#{Pathname.new($0).basename} server")
          opts.separator("")

          @params.each do |param|
            opts.on(param.alias_name, "--#{param.name}=#{param.name}", "--#{param.name} #{param.name}", param.desc) do |value|
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
  end
end
