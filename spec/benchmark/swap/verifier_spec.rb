# frozen_string_literal: true

RSpec.describe Benchmark::Swap::Verifier do
  subject(:verifier) { described_class.new }

  # Built by hand rather than discovered: some examples make the original side
  # raise, and discovery would hit that before the verifier ever runs.
  let(:candidates) { [Benchmark::Swap::Candidate.new(Subject, :work, :work_perf)] }
  let(:swapper) { Benchmark::Swap::Swapper.new(candidates) }
  let(:instance) { Subject.new }

  def build(original:, swapped:)
    klass = Class.new do
      define_method(:call) { work }
      define_method(:work) { instance_exec(&original) }
      define_method(:work_perf) { instance_exec(&swapped) }
    end
    stub_const("Subject", klass)
  end

  it "matches when both sides return the same value" do
    build(original: -> { 4 }, swapped: -> { 2 + 2 })

    expect(verifier.call(swapper) { instance.call }).to be_match
  end

  it "does not match when the values differ" do
    build(original: -> { 4 }, swapped: -> { 5 })
    outcome = verifier.call(swapper) { instance.call }

    expect(outcome).not_to be_match
    expect(outcome.original.to_s).to eq("4")
    expect(outcome.swapped.to_s).to eq("5")
  end

  it "does not match when only one side raises" do
    build(original: -> { 4 }, swapped: -> { raise ArgumentError, "nope" })
    outcome = verifier.call(swapper) { instance.call }

    expect(outcome).not_to be_match
    expect(outcome.swapped.to_s).to eq("ArgumentError: nope")
  end

  it "matches when both sides raise the same error" do
    build(original: -> { raise ArgumentError, "nope" }, swapped: -> { raise ArgumentError, "nope" })

    expect(verifier.call(swapper) { instance.call }).to be_match
  end

  it "does not match when the errors differ" do
    build(original: -> { raise ArgumentError, "nope" }, swapped: -> { raise TypeError, "nope" })

    expect(verifier.call(swapper) { instance.call }).not_to be_match
  end

  it "shortens a long value in the report" do
    build(original: -> { "a" * 500 }, swapped: -> { 5 })
    outcome = verifier.call(swapper) { instance.call }

    expect(outcome.original.to_s.length).to eq(described_class::MAX_LENGTH + 3)
    expect(outcome.original.to_s).to end_with("...")
  end

  it "restores the original bodies" do
    build(original: -> { 4 }, swapped: -> { 5 })
    verifier.call(swapper) { instance.call }

    expect(instance.call).to eq(4)
  end
end
