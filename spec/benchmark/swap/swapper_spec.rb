# frozen_string_literal: true

RSpec.describe Benchmark::Swap::Swapper do
  subject(:swapper) { described_class.new(candidates) }

  let(:candidates) { Benchmark::Swap::Discovery.new(suffix: "_perf").call { instance.call } }
  let(:instance) { klass.new }

  let(:klass) do
    Class.new do
      def call
        first + second
      end

      def first
        1
      end

      def first_perf
        10
      end

      private

      def second
        2
      end

      def second_perf
        20
      end
    end
  end

  before { stub_const("Subject", klass) }

  it "swaps every candidate at once" do
    expect(swapper.swapped { instance.call }).to eq(30)
  end

  it "restores the original bodies afterwards" do
    swapper.swapped { instance.call }

    expect(instance.call).to eq(3)
  end

  it "restores the original bodies when the block raises" do
    expect { swapper.swapped { raise "boom" } }.to raise_error("boom")
    expect(instance.call).to eq(3)
  end

  it "returns the block's value" do
    expect(swapper.swapped { :done }).to eq(:done)
  end

  it "keeps a private method private while swapped" do
    swapper.swapped do
      expect(klass.private_instance_methods(false)).to include(:second)
      expect(klass.public_instance_methods(false)).not_to include(:second)
    end
  end

  it "keeps a public method public while swapped" do
    swapper.swapped do
      expect(klass.public_instance_methods(false)).to include(:first)
    end
  end

  it "restores visibility afterwards" do
    swapper.swapped { instance.call }

    expect(klass.private_instance_methods(false)).to include(:second)
    expect(klass.public_instance_methods(false)).to include(:first)
  end

  it "does not leave the twin's body behind under the original name" do
    swapper.swapped { instance.call }

    expect(instance.first).to eq(1)
  end

  it "swaps a singleton method" do
    builder = Class.new do
      def self.build
        :original
      end

      def self.build_perf
        :swapped
      end
    end
    stub_const("Builder", builder)
    found = Benchmark::Swap::Discovery.new(suffix: "_perf").call { Builder.build }

    expect(described_class.new(found).swapped { Builder.build }).to eq(:swapped)
    expect(Builder.build).to eq(:original)
  end

  it "adds no call frame to the swapped side" do
    depth = Class.new do
      def call
        measure
      end

      def measure
        caller.size
      end

      def measure_perf
        caller.size
      end
    end
    stub_const("Depth", depth)
    subject_instance = Depth.new
    found = Benchmark::Swap::Discovery.new(suffix: "_perf").call { subject_instance.call }

    # Both sides run through Swapper#swapped, so the only difference left to
    # measure is the swap itself.
    original = described_class.new([]).swapped { subject_instance.call }
    swapped = described_class.new(found).swapped { subject_instance.call }

    expect(swapped).to eq(original)
  end

  it "refuses a candidate whose method the owner only inherits" do
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
    candidate = Benchmark::Swap::Candidate.new(Child, :shared, :shared_perf)

    expect { described_class.new([candidate]).enable }
      .to raise_error(ArgumentError, /Child does not define shared/)
  end

  context "when a module is prepended to the owner" do
    let(:patched) do
      patch = Module.new do
        def first
          super * 2
        end
      end

      Class.new do
        prepend patch

        def first
          1
        end

        def first_perf
          10
        end
      end
    end

    let(:instance) { patched.new }
    let(:found) { Benchmark::Swap::Discovery.new(suffix: "_perf").call { instance.first } }

    it "swaps the body the owner defines, below the prepended module" do
      expect(described_class.new(found).swapped { instance.first }).to eq(20)
    end

    it "restores the owner's own body and not the prepended one" do
      described_class.new(found).swapped { instance.first }

      expect(instance.first).to eq(2)
    end
  end
end
