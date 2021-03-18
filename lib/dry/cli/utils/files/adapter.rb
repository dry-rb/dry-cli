# frozen_string_literal: true

module Dry
  class CLI
    module Utils
      class Files
        # @since x.x.x
        # @api private
        class Adapter
          # @since x.x.x
          # @api private
          def self.call(memory:)
            if memory
              require_relative "./memory_file_system"
              MemoryFileSystem.new
            else
              require_relative "./file_system"
              FileSystem.new
            end
          end
        end
      end
    end
  end
end
