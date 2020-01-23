# frozen_string_literal: true

module Baz
  class CLI < Dry::CLI::Command
    desc 'Baz command line interface'
    argument :mandatory_arg, required: true, aliases: %w[m], desc: 'Mandatory argument'
    argument :optional_arg, aliases: %w[o],
                            desc: 'Optional argument (has to have default value in call method)'
    option :option_one, aliases: %w[1], desc: 'Option one'
    option :boolean_option, aliases: %w[b], desc: 'Option boolean', type: :boolean
    option :option_with_default, aliases: %w[d], desc: 'Option default', default: 'test'

    def call(mandatory_arg:, optional_arg: 'optional_arg', **options)
      puts "mandatory_arg: #{mandatory_arg}. " \
             "optional_arg: #{optional_arg}. " \
             "Options: #{options.inspect}"
    end
  end
end
