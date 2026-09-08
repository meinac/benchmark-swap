# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "benchmark/swap"

class Pow
  def initialize(number)
    @number = number
  end

  def pow
    do_pow
  end

  private

  def do_pow
    @number**2
  end

  def do_pow_perf
    @number * @number
  end
end

Benchmark.swap(time: 1, warmup: 1) { Pow.new(2).pow }
