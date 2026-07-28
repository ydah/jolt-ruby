# frozen_string_literal: true

module Jolt
  class FixedStepper
    attr_reader :step, :max_substeps

    def initialize(hz: 60, max_substeps: 5)
      frequency = Conversions.positive_float(hz, "hz")
      unless max_substeps.is_a?(Integer) && max_substeps.positive?
        raise InvalidArgumentError, "max_substeps must be a positive integer"
      end

      @step = 1.0 / frequency
      @max_substeps = max_substeps
      @accumulator = 0.0
    end

    def advance(delta_time)
      raise ArgumentError, "a block is required" unless block_given?

      @accumulator += Conversions.non_negative_float(delta_time, "delta_time")
      substeps = 0
      while @accumulator >= @step && substeps < @max_substeps
        yield @step
        @accumulator -= @step
        substeps += 1
      end
      @accumulator %= @step if @accumulator >= @step
      @accumulator / @step
    end

    def reset
      @accumulator = 0.0
      self
    end
  end
end
