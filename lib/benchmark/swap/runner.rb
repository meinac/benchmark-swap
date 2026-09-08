# frozen_string_literal: true

module Benchmark
  module Swap
    # Ties the three steps together:
    #   - find the twins
    #   - check both sides agree
    #   - benchmark each side
    #
    # Each side gets its own benchmark-ips run, because a single run executes
    # every report block after the setup block returns, which leaves no point
    # to turn the swap on between them.
    class Runner
      ORIGINAL_LABEL = "original"
      SWAPPED_LABEL = "swapped"
      PREFIX = "benchmark-swap:"

      Result = Struct.new(:candidates, :verification, :original, :swapped)

      def initialize(suffix:, verify:, output:, ips_options:)
        @suffix = suffix
        @verify = verify
        @output = output
        @ips_options = ips_options
      end

      def call(&block)
        candidates = Discovery.new(suffix: @suffix).call(&block)

        return nothing_found if candidates.empty?

        announce(candidates)

        swapper = Swapper.new(candidates)
        verification = verify(swapper, &block)
        original, swapped = benchmark(swapper, &block)

        Result.new(candidates, verification, original, swapped)
      end

      private

      def nothing_found
        say "#{PREFIX} no *#{@suffix} twin was called by this block, nothing to compare."

        nil
      end

      def announce(candidates)
        count = candidates.size
        say "#{PREFIX} swapping #{count} method#{"s" if count > 1}"
        candidates.each { |candidate| say "  #{candidate}" }
        say ""
      end

      def verify(swapper, &block)
        return unless @verify

        outcome = Verifier.new.call(swapper, &block)
        return outcome if outcome.match?

        say "#{PREFIX} WARNING both sides returned a different result"
        say "  #{ORIGINAL_LABEL}: #{outcome.original}"
        say "  #{SWAPPED_LABEL}: #{outcome.swapped}"
        say ""

        outcome
      end

      def benchmark(swapper, &block)
        original = ips(ORIGINAL_LABEL, &block)
        swapped = swapper.swapped { ips(SWAPPED_LABEL, &block) }

        Benchmark.compare(*original.entries, *swapped.entries, order: :baseline)

        [original, swapped]
      end

      def ips(label, &block)
        options = @ips_options

        Benchmark.ips do |job|
          job.config(**options) unless options.empty?
          job.report(label, &block)
        end
      end

      def say(line)
        @output.puts(line)
      end
    end
  end
end
