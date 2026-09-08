# frozen_string_literal: true

require "dry/cli/ticker"

RSpec.describe Dry::CLI::Ticker do
  before { @tickers = [] }

  after { @tickers.each(&:stop) }

  def start_ticker(interval:, &block)
    ticker = described_class.new(interval:)
    ticker.start(&block)
    @tickers << ticker
    ticker
  end

  describe ".start" do
    it "returns a ticker with the given interval" do
      ticker = described_class.start(interval: 0.42) {}
      @tickers << ticker

      expect(ticker).to be_an_instance_of(described_class)
      expect(ticker.interval).to eq(0.42)
    end
  end

  describe "#start" do
    it "returns self" do
      ticker = described_class.new(interval: 0.01)

      expect(ticker.start {}).to be ticker
      @tickers << ticker
    end

    it "yields to the block repeatedly" do
      queue = Queue.new
      start_ticker(interval: 0.02) { queue << true }

      sleep 0.1
      @tickers.each(&:stop)

      expect(queue.size).to be >= 3
    end

    it "waits the interval between ticks" do
      queue = Queue.new
      interval = 0.02
      start_ticker(interval:) { queue << Process.clock_gettime(Process::CLOCK_MONOTONIC) }

      sleep 0.1
      @tickers.each(&:stop)

      timestamps = []
      timestamps << queue.pop until queue.empty?
      gaps = timestamps.each_cons(2).map { |before, after| after - before }

      expect(gaps.min).to be >= interval / 2
    end
  end

  describe "#stop" do
    it "stops the thread so the block is no longer yielded" do
      queue  = Queue.new
      ticker = start_ticker(interval: 0.02) { queue << true }

      sleep 0.05
      ticker.stop
      count = queue.size

      sleep 0.05

      expect(queue.size).to eq(count)
    end

    it "is safe before start" do
      expect { described_class.new.stop }.not_to raise_error
    end

    it "can be called twice" do
      ticker = start_ticker(interval: 0.02) {}

      sleep 0.02
      ticker.stop

      expect { ticker.stop }.not_to raise_error
    end
  end
end
