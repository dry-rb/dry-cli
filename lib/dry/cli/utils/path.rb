# frozen_string_literal: true

module Dry
  class CLI
    module Utils
      module Path
        class << self
          def call(path)
            case path
            when Array
              Array(path).flatten
            else
              path.split(%r{\\/})
            end.join(::File::SEPARATOR)
          end
          alias_method :[], :call
        end
      end
    end
  end
end
