# frozen_string_literal: true

module Benchmark
  module Swap
    # A method that has a suffixed twin, plus the owner both are defined on.
    Candidate = Struct.new(:owner, :name, :perf_name) do
      def label
        if owner.singleton_class?
          "#{owner.attached_object}.#{name}"
        else
          "#{owner}##{name}"
        end
      rescue TypeError
        "#{owner}##{name}"
      end

      def to_s
        "#{label} -> #{perf_name}"
      end
    end
  end
end
