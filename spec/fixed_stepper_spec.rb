# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::FixedStepper do
  it "advances in fixed increments and returns the interpolation fraction" do
    steps = []
    stepper = described_class.new(hz: 10, max_substeps: 3)

    alpha = stepper.advance(0.25) { |step| steps << step }

    expect(steps).to contain_exactly(0.1, 0.1)
    expect(alpha).to be_within(1e-12).of(0.5)
  end

  it "drops excess accumulated time after the substep limit" do
    calls = 0
    stepper = described_class.new(hz: 60, max_substeps: 2)

    alpha = stepper.advance(1.0) { calls += 1 }

    expect(calls).to eq(2)
    expect(alpha).to be >= 0.0
    expect(alpha).to be < 1.0
  end

  it "rejects invalid timing values" do
    expect { described_class.new(hz: 0) }.to raise_error(Jolt::InvalidArgumentError)
    expect { described_class.new(max_substeps: 0) }.to raise_error(Jolt::InvalidArgumentError)
    expect { described_class.new.advance(-0.1) {} }.to raise_error(Jolt::InvalidArgumentError)
  end
end
