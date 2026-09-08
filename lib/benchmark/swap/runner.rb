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

      # Benchmark::IPS::Job#config reads the keys it knows and ignores the
      # rest, which would turn a typo into a benchmark that quietly ran with
      # the defaults.
      IPS_OPTIONS = %i[warmup time iterations stats confidence quiet suite].freeze

      Result = Struct.new(:candidates, :verification, :original, :swapped)

      def initialize(suffix:, verify:, output:, ips_options:)
        reject_unknown(ips_options)

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

      def reject_unknown(ips_options)
        unknown = ips_options.keys - IPS_OPTIONS
        return if unknown.empty?

        raise ArgumentError,
              "unknown option#{"s" if unknown.size > 1}: #{unknown.join(", ")}. " \
              "Known: #{IPS_OPTIONS.join(", ")}"
      end

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

        say "#{PREFIX} WARNING the two sides returned different results"
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
        Benchmark.ips do |job|
          job.config(**@ips_options) unless @ips_options.empty?
          job.report(label, &block)
        end
      end

      def say(line)
        @output.puts(line)
      end
    end
  end
end
