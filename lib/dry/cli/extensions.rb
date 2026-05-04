# frozen_string_literal: true

module Dry
  class CLI
    # Provides extension support based on Dry::Core::Extension.
    # This module should only ever be used internally.
    module Extensions
      # @api private
      def self.extended(obj)
        super
        obj.instance_variable_set(:@__available_extensions__, {})
        obj.instance_variable_set(:@__loaded_extensions__, ::Set.new)
      end

      def register_extension(name, &block)
        @__available_extensions__[name] = block
      end

      def loaded_extension?(name)
        @__loaded_extensions__&.include?(name)
      end

      def unload_extension(name)
        @__loaded_extensions__.delete(name)
      end

      def available_extension?(name)
        @__available_extensions__.key?(name)
      end

      def load_extensions(*extensions)
        extensions.each do |ext|
          block = @__available_extensions__.fetch(ext) do
            raise ::ArgumentError, "Unknown extension: #{ext.inspect}"
          end
          unless @__loaded_extensions__.include?(ext)
            block.call
            @__loaded_extensions__ << ext
          end
        end
      end
    end
  end
end
