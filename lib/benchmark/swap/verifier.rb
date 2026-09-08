# frozen_string_literal: true

module Benchmark
  module Swap
    # Runs the block once per side and compares the outcomes. A mismatch is a
    # warning, never an error: the block may return something that does not
    # compare with ==, and that is the caller's call to make.
    class Verifier
      # An inspect of a real object graph can fill the console, and this is
      # only here to show the reader what differed.
      MAX_LENGTH = 200

      Result = Struct.new(:value, :error) do
        def self.capture
          new(yield, nil)
        rescue StandardError, ScriptError => e
          new(nil, e)
        end

        def match?(other)
          return value == other.value unless error || other.error

          other.error.instance_of?(error.class) && other.error.message == error.message
        rescue StandardError
          # Comparing is best effort, and this class promises a warning rather
          # than a failure. A value that raises from == counts as a difference.
          false
        end

        def to_s
          return "#{error.class}: #{error.message}" if error

          text = value.inspect
          text.length > MAX_LENGTH ? "#{text[0, MAX_LENGTH]}..." : text
        rescue StandardError
          "(cannot be shown)"
        end
      end

      Outcome = Struct.new(:original, :swapped) do
        def match?
          original.match?(swapped)
        end
      end

      def call(swapper, &block)
        original = Result.capture(&block)
        swapped = swapper.swapped { Result.capture(&block) }

        Outcome.new(original, swapped)
      end
    end
  end
end
