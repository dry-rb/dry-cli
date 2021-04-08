# frozen_string_literal: true

module Dry
  class CLI
    module Utils
      module Path
        class << self
          def call(*path)
            path = Array(path).flatten
            tokens = path.map do |token|
              token.split(/\\|\//)
            end

            tokens.
              flatten.
              join(::File::SEPARATOR)
          end
          alias_method :[], :call
        end
      end
    end
  end
end
