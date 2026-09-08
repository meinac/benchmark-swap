# frozen_string_literal: true

RSpec.describe Benchmark::Swap do
  let(:output) { StringIO.new }
  let(:options) { { time: 0.01, warmup: 0.01, output: output } }
  let(:instance) { Subject.new }

  let(:klass) do
    Class.new do
      def call
        do_work
      end

      private

      def do_work
        4
      end

      def do_work_perf
        2 + 2
      end
    end
  end

  before { stub_const("Subject", klass) }

  def run(**extra, &block)
    capture_stdout { described_class.test(**options, **extra, &block) }
  end

  it "raises without a block" do
    expect { described_class.test }.to raise_error(ArgumentError, "a block is required")
  end

  it "lists the methods it swapped" do
    run { instance.call }

    expect(output.string).to include("benchmark-swap: swapping 1 method", "Subject#do_work -> do_work_perf")
  end

  it "benchmarks both sides and compares them" do
    printed = run { instance.call }

    expect(printed).to include("original", "swapped", "Comparison:")
  end

  it "returns both reports" do
    result = nil
    capture_stdout { result = described_class.test(**options) { instance.call } }

    expect(result.original.entries.map(&:label)).to eq(["original"])
    expect(result.swapped.entries.map(&:label)).to eq(["swapped"])
    expect(result.candidates.map(&:name)).to eq([:do_work])
  end

  it "restores the original bodies when it is done" do
    run { instance.call }

    expect(instance.call).to eq(4)
  end

  it "says nothing was found when no twin is called" do
    result = nil
    capture_stdout { result = described_class.test(**options) { 1 + 1 } }

    expect(result).to be_nil
    expect(output.string).to include("no *_perf twin was called by this block")
  end

  it "warns when the two sides disagree" do
    klass.send(:define_method, :do_work_perf) { 5 }
    run { instance.call }

    expect(output.string).to include(
      "WARNING both sides returned a different result",
      "original: 4",
      "swapped: 5"
    )
  end

  it "skips the check when verification is off" do
    klass.send(:define_method, :do_work_perf) { 5 }
    run(verify: false) { instance.call }

    expect(output.string).not_to include("WARNING")
  end

  it "honours a custom suffix" do
    klass.send(:define_method, :do_work_faster) { 6 }
    run(suffix: "_faster") { instance.call }

    expect(output.string).to include("Subject#do_work -> do_work_faster")
  end

  it "is available as Benchmark.swap" do
    printed = capture_stdout { Benchmark.swap(**options) { instance.call } }

    expect(printed).to include("Comparison:")
  end
end
