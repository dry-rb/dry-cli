# frozen_string_literal: true

require "fileutils"

module Dry
  class CLI
    module Utils
      class Files
        class FileSystem
          # Creates a new instance
          #
          # @param file [Class]
          # @param file_utils [Class]
          #
          # @return [Dry::CLI::Utils::Files::FileSystem]
          #
          # @since x.x.x
          def initialize(file: File, file_utils: FileUtils)
            @file = file
            @file_utils = file_utils
          end

          def touch(path, **kwargs)
            file_utils.touch(path, **kwargs)
          end

          def cp(source, destination, **kwargs)
            file_utils.cp(source, destination, **kwargs)
          end

          def mkdir(path, **kwargs)
            file_utils.mkdir_p(path, **kwargs)
          end

          def mkdir_p(path, **kwargs)
            mkdir(
              file.dirname(path), **kwargs
            )
          end

          def rm(path, **kwargs)
            file_utils.rm(path, **kwargs)
          end

          def rm_rf(path, *args)
            file_utils.remove_entry_secure(path, *args)
          end

          def readlines(path, *args)
            file.readlines(path, *args)
          end

          def exist?(path)
            file.exist?(path)
          end

          def directory?(path)
            file.directory?(path)
          end

          def open(path, *args, &blk)
            file.open(path, *args, &blk)
          end

          private

          attr_reader :file

          attr_reader :file_utils
        end
      end
    end
  end
end
