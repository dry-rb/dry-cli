# frozen_string_literal: true

require "English"
require "stringio"

module Dry
  class CLI
    module Utils
      class Files
        class MemoryFileSystem
          class Node
            def initialize
              @children = nil
              @content = nil
            end

            def put(segment)
              @children ||= {}
              @children[segment] ||= self.class.new
            end

            def get(segment)
              @children&.fetch(segment, nil)
            end

            def directory?
              !file?
            end

            def file?
              !@content.nil?
            end

            def file!(*content)
              @content = StringIO.new(content.join($RS))
            end

            alias_method :write, :file!

            def read
              @content.rewind
              @content.read
            end

            def readlines
              @content.rewind
              @content.readlines
            end
          end
        end
      end
    end
  end
end
