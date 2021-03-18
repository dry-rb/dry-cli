# frozen_string_literal: true

require "English"

module Dry
  class CLI
    module Utils
      class Files
        class MemoryFileSystem
          class Node
            attr_reader :content

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
              @content = content.join($RS)
            end

            alias_method :write, :file!
          end
        end
      end
    end
  end
end
