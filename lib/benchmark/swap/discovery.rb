# frozen_string_literal: true

module Benchmark
  module Swap
    # Runs the block once under a TracePoint and keeps every method call that
    # has a twin with the configured suffix on the same owner.
    class Discovery
      def initialize(suffix:)
        @suffix = suffix
      end

      def call(&block)
        seen = Set.new
        found = []
        thread = Thread.current

        trace = TracePoint.new(:call) do |trace_point|
          next unless Thread.current.equal?(thread)

          owner = trace_point.defined_class
          name = trace_point.method_id
          key = [owner.object_id, name]

          next unless seen.add?(key)

          candidate = candidate_for(owner, name)

          found << candidate if candidate
        end

        trace.enable(&block)

        found
      end

      private

      def candidate_for(owner, name)
        return unless owner.is_a?(Module)
        return if owner.frozen?
        return if name.nil? || name.to_s.end_with?(@suffix)

        perf_name = :"#{name}#{@suffix}"
        return unless own_method?(owner, name) && own_method?(owner, perf_name)

        Candidate.new(owner, name, perf_name)
      end

      def own_method?(owner, name)
        owner.public_method_defined?(name, false) ||
          owner.private_method_defined?(name, false) ||
          owner.protected_method_defined?(name, false)
      end
    end
  end
end
