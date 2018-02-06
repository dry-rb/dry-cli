require 'hanami/utils/callbacks'
require 'hanami/utils/class_attribute'

module Hanami
  class CLI
    # Extention module for command callbacks
    #
    # @since 0.1.0
    module Callbacks
      def self.included(base)
        base.class_eval do
          extend  ClassMethods
          prepend InstanceMethods
        end
      end

      module ClassMethods
        def self.extended(base)
          base.class_eval do
            include Utils::ClassAttribute

            class_attribute :before_callbacks
            self.before_callbacks = Utils::Callbacks::Chain.new

            class_attribute :after_callbacks
            self.after_callbacks = Utils::Callbacks::Chain.new
          end
        end

        def append_before(*callbacks, &blk)
          before_callbacks.append(*callbacks, &blk)
        end

        alias_method :before, :append_before

        def append_after(*callbacks, &blk)
          after_callbacks.append(*callbacks, &blk)
        end

        alias_method :after, :append_after
      end

      module InstanceMethods
        def call(params)
          _run_before_callbacks(params)
          super
          _run_after_callbacks(params)
        end

        private
        # @since 0.1.0
        # @api private
        def _run_before_callbacks(params)
          self.class.before_callbacks.run(self, params)
        end

        # @since 0.1.0
        # @api private
        def _run_after_callbacks(params)
          self.class.after_callbacks.run(self, params)
        end
      end
    end
  end
end

