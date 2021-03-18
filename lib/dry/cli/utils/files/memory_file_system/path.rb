# frozen_string_literal: true

module Dry
  class CLI
    module Utils
      class Files
        class MemoryFileSystem
          module Path
            class << self
              def call(path)
                path.split(%r{\\/}).join(::File::SEPARATOR)
              end
              alias_method :[], :call
            end
          end
        end
      end
    end
  end
end
