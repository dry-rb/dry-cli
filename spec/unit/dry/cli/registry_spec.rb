# frozen_string_literal: true

RSpec.describe Dry::CLI::Registry do
  describe '.before' do
    context "when command can't be found" do
      it 'raises error' do
        expect do
          Bar::CLI::Commands.before('pixel') { puts 'hello' }
        end.to raise_error(Dry::CLI::UnknownCommandError, "unknown command: `pixel'")
      end
    end

    context 'when object is given' do
      it "raises error when it doesn't respond to #call" do
        callback = Object.new

        expect do
          Bar::CLI::Commands.before('alpha', callback)
        end.to raise_error(
          Dry::CLI::InvalidCallbackError, "expected `#{callback.inspect}' to respond to `#call'"
        )
      end
    end

    context 'when class is given' do
      it 'raises error when #initialize arity is not equal to 0' do
        callback = Struct

        expect do
          Bar::CLI::Commands.before('alpha', callback)
        end.to raise_error(
          Dry::CLI::InvalidCallbackError,
          "expected `#{callback.inspect}' to respond to `#initialize' with arity 0"
        )
      end
    end
  end

  describe '.after' do
    context "when command can't be found" do
      it 'raises error' do
        expect do
          Bar::CLI::Commands.after('peta') { puts 'hello' }
        end.to raise_error(Dry::CLI::UnknownCommandError, "unknown command: `peta'")
      end
    end

    context 'when object is given' do
      it "raises error when it doesn't respond to #call" do
        callback = Object.new

        expect do
          Bar::CLI::Commands.after('alpha', callback)
        end.to raise_error(
          Dry::CLI::InvalidCallbackError,
          "expected `#{callback.inspect}' to respond to `#call'"
        )
      end
    end

    context 'when class is given' do
      it 'raises error when #initialize arity is not equal to 0' do
        callback = Struct

        expect do
          Bar::CLI::Commands.after('alpha', callback)
        end.to raise_error(
          Dry::CLI::InvalidCallbackError,
          " expected `#{callback.inspect}' to respond to `#initialize' with arity 0"
        )
      end
    end
  end
end
