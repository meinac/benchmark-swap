# frozen_string_literal: true

require "benchmark/ips"

require_relative "swap/version"
require_relative "swap/candidate"
require_relative "swap/discovery"
require_relative "swap/swapper"
require_relative "swap/verifier"
require_relative "swap/runner"

module Benchmark
  # Benchmarks a second implementation of a method where it already runs.
  #
  #   class Pow
  #     def pow
  #       do_pow
  #     end
  #
  #     private
  #
  #     def do_pow
  #       @number**2
  #     end
  #
  #     def do_pow_perf
  #       @number * @number
  #     end
  #   end
  #
  #   Benchmark.swap { Pow.new(2).pow }
  module Swap
    DEFAULT_SUFFIX = "_perf"

    class << self
      # @param suffix [String] the twin's name suffix
      # @param verify [Boolean] compare both sides once before benchmarking
      # @param output [IO] where the swap report goes
      # @param ips_options [Hash] passed to benchmark-ips, e.g. time:, warmup:
      # @return [Runner::Result, nil] nil when no twin was called
      def test(suffix: DEFAULT_SUFFIX, verify: true, output: $stdout, **ips_options, &block)
        raise ArgumentError, "a block is required" unless block

        Runner.new(suffix: suffix, verify: verify, output: output, ips_options: ips_options).call(&block)
      end
    end
  end

  def self.swap(...)
    Swap.test(...)
  end
end
