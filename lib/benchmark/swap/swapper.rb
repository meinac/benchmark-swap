# frozen_string_literal: true

module Benchmark
  module Swap
    # Copies each twin's body onto the original method name, and puts the
    # original body back afterwards.
    #
    # define_method with an UnboundMethod copies the body instead of
    # delegating to it, so both sides of the benchmark run at the same call
    # depth and the numbers describe the bodies, not the swap.
    class Swapper
      def initialize(candidates)
        @candidates = candidates
        @saved = []
      end

      def swapped
        enable
        yield
      ensure
        disable
      end

      def enable
        @candidates.each do |candidate|
          owner = candidate.owner
          original = own_instance_method(owner, candidate.name)
          visibility = visibility_of(owner, candidate.name)

          define(owner, candidate.name, own_instance_method(owner, candidate.perf_name), visibility)
          @saved << [owner, candidate.name, original, visibility]
        end
      end

      def disable
        while (entry = @saved.pop)
          define(*entry)
        end
      end

      private

      # A module prepended to the owner shadows the owner's own definition, so
      # Module#instance_method can hand back a body the owner does not own.
      # Saving that body and writing it back on restore would overwrite the
      # real one for good, so walk down to the definition the owner itself
      # holds.
      def own_instance_method(owner, name)
        method = owner.instance_method(name)
        method = method.super_method until method.nil? || method.owner.equal?(owner)

        method || raise(ArgumentError, "#{owner} does not define #{name}, it only inherits it")
      end

      def define(owner, name, body, visibility)
        owner.send(:define_method, name, body)
        owner.send(visibility, name)
      end

      def visibility_of(owner, name)
        if owner.private_method_defined?(name, false)
          :private
        elsif owner.protected_method_defined?(name, false)
          :protected
        else
          :public
        end
      end
    end
  end
end
