require "hanami/cli/param"

module Hanami
  class Cli
    class Command
      module ClassInterface
        UNDEFINED = Object.new.freeze

        def new(**options)
          super(options.merge(description: desc, params: params))
        end

        def desc(new_description = UNDEFINED)
          if new_description == UNDEFINED
            @desc if instance_variable_defined?(:@desc)
          else
            @desc = new_description
          end
        end

        def params
          @params ||= []
        end

        #
        # FIXME: Use custom argument class instead Param class
        #
        def argument(name, **options)
          option(name, options.merge(argument: true))
        end

        #
        # FIXME: Use custom option class instead Param class
        #
        def option(name, **options)
          params << Param.new(name, options)
        end
      end
    end
  end
end
