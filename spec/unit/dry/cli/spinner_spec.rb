# frozen_string_literal: true

require "dry/cli/ticker"

RSpec.describe Dry::CLI::Spinner do
  subject(:spinner) { described_class.new(frames: %w[| / -], fps: 10) }

  let(:terminal) { StringIO.new.tap { |io| def io.tty? = true } }
  let(:file) { StringIO.new }
  let(:ticker) { instance_double(Dry::CLI::Ticker, stop: nil) }
  let(:tick_blocks) { [] }
  let(:intervals) { [] }

  around do |example|
    Dry::CLI::Style.enabled = true
    Dry::CLI::Style.color_level = :truecolor
    example.run
    Dry::CLI::Style.enabled = nil
    Dry::CLI::Style.color_level = nil
  end

  before do
    allow(Dry::CLI::Ticker).to receive(:start) do |interval:, &block|
      intervals << interval
      tick_blocks << block
      ticker
    end
  end

  def render_ticks(count = 1)
    count.times { tick_blocks.last.call }
  end

  describe "#run format" do
    it "accepts a String" do
      spinner.run("%{spinner} Loading", stream: terminal) { render_ticks }

      expect(terminal.string).to include "| Loading"
    end

    it "accepts Dry::CLI::Style::Text" do
      format = Dry::CLI::Style.bold["%{spinner}"] + " Loading"

      spinner.run(format, stream: terminal) { render_ticks }

      expect(terminal.string).to include "\e[1m|\e[0m Loading"
    end

    it "interpolates data registered by before_tick" do
      format = Dry::CLI::Style.bold["%{spinner}"] + " %{remaining}s"

      spinner.run(format, stream: terminal) do |s|
        s.before_tick { |_stream, data| data[:remaining] = 5 }
        s.run {}
      end
      render_ticks

      expect(terminal.string).to include "\e[1m|\e[0m 5s"
    end

    it "defaults to %{spinner}" do
      spinner.run(stream: terminal) { render_ticks }

      expect(terminal.string).to include "|"
    end
  end

  describe "#run stream" do
    let(:stream_matcher) do
      an_instance_of(Dry::CLI::Stream).and(satisfy { |stream| stream.raw.equal?(terminal) })
    end

    it "yields a raw IO to before_tick as a Dry::CLI::Stream, with the tick data" do
      expect { |hook|
        spinner.run(stream: terminal) do |s|
          s.before_tick(&hook)
          s.run {}
        end
        render_ticks(2)
      }.to yield_successive_args(
        [stream_matcher, hash_including(spinner: "|")],
        [stream_matcher, hash_including(spinner: "/")]
      )
    end

    it "yields a raw IO to after_tick as a Dry::CLI::Stream" do
      expect { |hook|
        spinner.run(stream: terminal) do |s|
          s.after_tick(&hook)
          s.run {}
        end
        render_ticks(2)
      }.to yield_successive_args(stream_matcher, stream_matcher)
    end

    it "passes a Dry::CLI::Stream through unchanged" do
      stream = Dry::CLI::Stream.for(terminal)
      yielded = nil

      spinner.run(stream: stream) do |s|
        s.before_tick { |yielded_stream, _data| yielded = yielded_stream }
        s.run {}
      end
      render_ticks

      expect(yielded).to be stream
    end

    it "draws nothing for a stream that is not a terminal, but still runs the worker" do
      worker_ran = false

      spinner.run(stream: file) { worker_ran = true }

      expect(worker_ran).to be true
      expect(file.string).to eq ""
      expect(Dry::CLI::Ticker).to_not have_received(:start)
    end
  end

  describe "#run block" do
    it "treats a zero-arity block as the worker" do
      calls = 0

      spinner.run(stream: terminal) { calls += 1 }

      expect(calls).to eq 1
    end

    it "runs the worker registered through the DSL" do
      events = []

      spinner.run("%{spinner} %{remaining}", stream: terminal) do |s|
        s.before_tick do |_stream, data|
          events << [:before, data[:spinner]]
          data[:remaining] = 5
        end
        s.after_tick { |_stream| events << [:after] }
        s.run { events << [:run] }
      end
      render_ticks

      expect(events).to eq [[:run], [:before, "|"], [:after]]
      expect(terminal.string).to include "| 5"
    end

    it "runs the hooks around the formatted line" do
      spinner.run("frame", stream: terminal) do |s|
        s.before_tick { |stream, _data| stream.print "<" }
        s.after_tick { |stream| stream.print ">" }
        s.run {}
      end
      render_ticks

      expect(terminal.string).to include "#{Dry::CLI::ANSI.erase_line}<frame>"
    end

    it "does not need the DSL to register a worker" do
      expect { spinner.run(stream: terminal) { |_s| } }.to_not raise_error
    end
  end

  describe "#run ticker" do
    it "uses the spinner's fps by default" do
      spinner.run(stream: terminal) {}

      expect(intervals).to eq [0.1]
    end

    it "accepts an fps override" do
      spinner.run(stream: terminal, fps: 4) {}

      expect(intervals).to eq [0.25]
    end

    it "cycles through the frames on each tick" do
      spinner.run(stream: terminal) { render_ticks(2) }

      expect(terminal.string).to include "#{Dry::CLI::ANSI.erase_line}|"
      expect(terminal.string).to include "#{Dry::CLI::ANSI.erase_line}/"
    end
  end

  describe "#run cleanup" do
    let(:cleanup) do
      Dry::CLI::ANSI.hide_cursor +
        Dry::CLI::ANSI.erase_line +
        Dry::CLI::ANSI.show_cursor
    end

    it "stops the ticker and shows the cursor when the worker finishes" do
      spinner.run(stream: terminal) {}

      expect(ticker).to have_received(:stop)
      expect(terminal.string).to eq cleanup
    end

    it "stops the ticker when the worker raises" do
      expect {
        spinner.run(stream: terminal) { raise "boom" }
      }.to raise_error("boom")

      expect(ticker).to have_received(:stop)
      expect(terminal.string).to eq cleanup
    end

    it "cleans up when a worker registered through the DSL raises" do
      expect {
        spinner.run(stream: terminal) { |s| s.run { raise "boom" } }
      }.to raise_error("boom")

      expect(ticker).to have_received(:stop)
      expect(terminal.string).to eq cleanup
    end
  end

  describe "with a real ticker" do
    before { allow(Dry::CLI::Ticker).to receive(:start).and_call_original }

    it "renders frames while the worker runs" do
      deadline = Time.now + 2

      spinner.run(stream: terminal, fps: 100) do
        sleep(0.01) until terminal.string.include?("|") || Time.now > deadline
      end

      expect(terminal.string).to include "|"
      expect(terminal.string).to end_with Dry::CLI::ANSI.show_cursor
    end
  end
end
