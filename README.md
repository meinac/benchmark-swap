# Benchmark::Swap

[![CI](https://github.com/meinac/benchmark-swap/actions/workflows/ci.yml/badge.svg)](https://github.com/meinac/benchmark-swap/actions/workflows/ci.yml)

Compare two implementations of a method end to end, where the method already runs. `Benchmark::Swap` swaps the body in place, so your block calls the public entry point and the measurement covers the whole call chain.

That is the point of the gem. A method measured on its own can report a speed-up that the caller never feels, because the rest of the call chain dwarfs it. The end-to-end number is the one that tells you whether the change is worth making. Lifting the method into two standalone lambdas gives you the isolated number instead, and it is slow to do and easy to get wrong when the method sits deep inside real code.

Built for exploring performance changes inside a large Rails app from the Rails console.

## Installation

Add this line to your Gemfile:

```ruby
gem "benchmark-swap"
```

Then run `bundle install`.

Requires Ruby 3.2 or newer. Depends on `benchmark-ips`.

## Usage

Keep the original method. Add a second implementation next to it, with the same name plus a `_perf` suffix:

```ruby
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

Benchmark.swap { Pow.new(2).pow }
```

`Benchmark.swap` is a shortcut for `Benchmark::Swap.test`. Both take the same options.

Sample output:

```
benchmark-swap: swapping 1 method
  Pow#do_pow -> do_pow_perf

ruby 3.3.11 (2026-03-26 revision 1f2d15125a) [arm64-darwin24]
Warming up --------------------------------------
            original   848.389k i/100ms
Calculating -------------------------------------
            original      8.480M (± 0.3%) i/s  (117.93 ns/i) -      8.484M in   1.000511s
ruby 3.3.11 (2026-03-26 revision 1f2d15125a) [arm64-darwin24]
Warming up --------------------------------------
             swapped   905.345k i/100ms
Calculating -------------------------------------
             swapped      9.083M (± 0.2%) i/s  (110.09 ns/i) -      9.959M in   1.096372s

Comparison:
original:  8479556.9 i/s
 swapped:  9083408.7 i/s - 1.07x  faster
```

Two "Warming up / Calculating" blocks and one "Comparison:" block are expected. Each side gets its own benchmark-ips run, then the two are compared with the original as the baseline.

Pass `quiet: true` if you want only the swap list and the comparison.

## How it works

1. **Discovery.** The block runs once under a Ruby `TracePoint` on the `:call` event. It collects every method that was actually called and has a twin with the suffix defined on the same owner. Only calls from the current thread count. A method whose twin lives on a different class or module (for example the original on a parent class, the twin on the child) is skipped. Frozen owners are skipped too.
2. **Verification.** The block runs once per side, and the two results are compared with `==`. A mismatch prints a warning, but the benchmark still runs: this step never raises. If both sides raise the same error class and message, that also counts as a match. Turn it off with `verify: false`.
3. **Benchmark.** Each side gets its own benchmark-ips run, then `Benchmark.compare` reports the two with the original as the baseline.

All discovered twins are swapped together. There is no one-at-a-time mode in this version.

The swap itself copies the twin's `UnboundMethod` body onto the original method name with `define_method`, keeping the original body aside, and puts it back afterwards. It does not delegate through a wrapper method, so both sides run at the same call depth and the numbers describe the method bodies, not the swap. A spec proves this by comparing `caller.size` on both sides. Method visibility (public, protected, private) is preserved and restored. Originals are restored even when the block raises. When a module is prepended to the owner, the swap targets the definition the owner itself holds, so a prepended override that calls `super` keeps working and its own body is left untouched.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `suffix:` | `"_perf"` | Suffix used to find the twin method |
| `verify:` | `true` | Compare both sides once before benchmarking |
| `output:` | `$stdout` | Where the gem's own report lines go |
| anything else | | Passed to benchmark-ips config: `warmup`, `time`, `iterations`, `stats`, `confidence`, `quiet`, `suite` |

Any other key raises `ArgumentError`, because benchmark-ips would otherwise ignore it and run with the defaults.

The call returns a `Runner::Result` struct with `candidates`, `verification`, `original`, and `swapped`. `original` and `swapped` are benchmark-ips `Report` objects. It returns `nil` when no twin was called.

## Caveats

- The block runs several times: once for discovery, twice for verification, then many times per benchmark side. Side effects add up, so build fresh objects inside the block instead of reusing a memoised one.
- If the block raises during discovery, the error propagates.
- The check step compares the two results with `==`. A block that ends in a public entry point often returns an object that does not define `==`, so the two runs never compare equal and you get a warning about a difference that is not there. Return something comparable instead, for example a list of ids.
- Only methods defined in Ruby are found. The TracePoint `:call` event does not fire for methods implemented in C, so an `attr_reader` original, or a method from a C extension, is skipped even when a twin exists next to it. Write the original in Ruby if you want to measure it.
- While a side is being measured, the swap is visible to the whole process, not just the calling thread. Discovery only watches the current thread, but the swapped body is what every thread sees. So do not run this on a process that is serving real traffic.
- Remember to delete the `_perf` method before you commit.

## Development

```
bundle install
bundle exec rspec
bundle exec rubocop
ruby examples/pow.rb
```

## License

MIT.
