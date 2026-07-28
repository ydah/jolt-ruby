# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::Shape do
  after do
    @shape&.release
  end

  it "creates the basic Jolt shapes" do
    shapes = [
      described_class.box([1, 2, 3]),
      described_class.sphere(0.5),
      described_class.capsule(half_height: 1.0, radius: 0.25),
      described_class.cylinder(half_height: 1.0, radius: 0.5)
    ]

    expect(shapes.map(&:volume)).to all(be_positive)
  ensure
    shapes&.each(&:release)
  end

  it "validates dimensions" do
    expect { described_class.box([1, 0, 1]) }.to raise_error(Jolt::InvalidArgumentError)
    expect { described_class.sphere(-1) }.to raise_error(Jolt::InvalidArgumentError)
    expect do
      described_class.capsule(half_height: 1, radius: 0)
    end.to raise_error(Jolt::InvalidArgumentError)
  end

  it "rejects access after release" do
    @shape = described_class.sphere(1)
    @shape.release

    expect { @shape.volume }.to raise_error(Jolt::UseAfterDestroyError)
  end
end
