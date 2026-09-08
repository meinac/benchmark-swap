# frozen_string_literal: true

RSpec.describe Benchmark::Swap::Discovery do
  subject(:discovery) { described_class.new(suffix: "_perf") }

  let(:klass) do
    Class.new do
      def call
        with_twin + without_twin
      end

      def with_twin
        1
      end

      def with_twin_perf
        2
      end

      def without_twin
        3
      end
    end
  end

  before { stub_const("Subject", klass) }

  it "finds a called method that has a twin" do
    candidates = discovery.call { Subject.new.call }

    expect(candidates.map(&:to_s)).to eq(["Subject#with_twin -> with_twin_perf"])
  end

  it "ignores a method that is never called" do
    candidates = discovery.call { Subject.new.without_twin }

    expect(candidates).to be_empty
  end

  it "does not look for a twin of a twin" do
    candidates = discovery.call { Subject.new.with_twin_perf }

    expect(candidates).to be_empty
  end

  it "reports a method only once, however many times it runs" do
    candidates = discovery.call { 3.times { Subject.new.with_twin } }

    expect(candidates.size).to eq(1)
  end

  it "honours a custom suffix" do
    klass.send(:define_method, :with_twin_alt) { 4 }
    candidates = described_class.new(suffix: "_alt").call { Subject.new.with_twin }

    expect(candidates.map(&:perf_name)).to eq([:with_twin_alt])
  end

  it "finds a private twin of a private method" do
    private_klass = Class.new do
      def call
        hidden
      end

      private

      def hidden
        1
      end

      def hidden_perf
        2
      end
    end
    stub_const("Hidden", private_klass)

    candidates = discovery.call { Hidden.new.call }

    expect(candidates.map(&:to_s)).to eq(["Hidden#hidden -> hidden_perf"])
  end

  it "finds a singleton method" do
    singleton_klass = Class.new do
      def self.build
        :original
      end

      def self.build_perf
        :swapped
      end
    end
    stub_const("Builder", singleton_klass)

    candidates = discovery.call { Builder.build }

    expect(candidates.map(&:to_s)).to eq(["Builder.build -> build_perf"])
  end

  it "ignores a twin that lives on another owner" do
    parent = Class.new do
      def shared
        1
      end
    end
    child = Class.new(parent) do
      def shared_perf
        2
      end
    end
    stub_const("Child", child)

    candidates = discovery.call { Child.new.shared }

    expect(candidates).to be_empty
  end

  it "skips a frozen owner, which could not be swapped anyway" do
    frozen_klass = Class.new do
      def call
        1
      end

      def call_perf
        2
      end
    end
    stub_const("Frozen", frozen_klass.freeze)

    expect(discovery.call { Frozen.new.call }).to be_empty
  end

  it "returns nothing when the block calls no Ruby method" do
    expect(discovery.call { 42 }).to be_empty
  end
end
