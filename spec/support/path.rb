# frozen_string_literal: true

module RSpec
  module Support
    module Path
      def self.included(base)
        base.class_eval do
          before do
            @original_path = ENV['PATH']
            ENV['PATH'] = __dir__ + '/fixtures:' + ENV['PATH']
          end

          after do
            ENV['PATH'] = @original_path
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Support::Path)
end
