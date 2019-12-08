# frozen_string_literal: true

RSpec.describe Dry::CLI do
  describe 'UnkwnownCommandError' do
    it 'shows deprecation message' do
      expect do
        Dry::CLI::UnkwnownCommandError.new(:foo)
      end.to output(include('UnkwnownCommandError is deprecated, please use UnknownCommandError')).to_stderr
    end
  end
end
