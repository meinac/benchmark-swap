# frozen_string_literal: true

RSpec.describe Benchmark::Swap::Candidate do
  it "names an instance method with its owner" do
    stub_const("Subject", Class.new)

    expect(described_class.new(Subject, :call, :call_perf).to_s).to eq("Subject#call -> call_perf")
  end

  it "names a singleton method after the object it hangs on" do
    stub_const("Subject", Class.new)

    expect(described_class.new(Subject.singleton_class, :build, :build_perf).label).to eq("Subject.build")
  end

  it "falls back to the owner when the object refuses to describe itself" do
    rude = Class.new do
      def to_s
        raise "no to_s here"
      end
    end
    owner = rude.new.singleton_class

    expect(owner.singleton_class?).to be(true)
    expect(described_class.new(owner, :call, :call_perf).label).to match(/\A#<Class:#<.*>>#call\z/)
  end
end
