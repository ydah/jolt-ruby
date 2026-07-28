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

  it "builds hulls and meshes from packed buffers" do
    points = [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1].pack("e*")
    vertices = [-1, 0, -1, 1, 0, -1, 1, 0, 1, -1, 0, 1].pack("e*")
    indices = [0, 1, 2, 0, 2, 3].pack("V*")
    shapes = [
      described_class.convex_hull(points),
      described_class.mesh(vertices:, indices:)
    ]

    expect(shapes.first.volume).to be_within(1e-6).of(1.0 / 6.0)
    expect(shapes.last).to be_must_be_static
  ensure
    shapes&.each(&:release)
  end

  it "rejects packed buffers with trailing partial values" do
    valid_points = [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1].pack("e*")
    valid_vertices = [-1, 0, -1, 1, 0, -1, 1, 0, 1].pack("e*")

    expect do
      described_class.convex_hull(valid_points + "\0".b)
    end.to raise_error(Jolt::InvalidArgumentError, /trailing bytes/)
    expect do
      described_class.mesh(vertices: valid_vertices, indices: [0, 1, 2].pack("V*") + "\0".b)
    end.to raise_error(Jolt::InvalidArgumentError, /trailing bytes/)
  end

  it "builds heightfields, compounds, and decorated shapes" do
    child = described_class.sphere(1)
    shapes = [
      described_class.heightfield(samples: Array.new(16, 0), size: 4),
      described_class.compound([[child, [0, 0, 0], [0, 0, 0, 1]]]),
      described_class.scaled(child, [2, 2, 2]),
      described_class.offset(child, position: [1, 0, 0])
    ]

    expect(shapes.map(&:kind)).to eq(%i[heightfield compound scaled offset])
    expect(shapes.first).to be_must_be_static
    expect(shapes.drop(1).map(&:volume)).to all(be_positive)
  ensure
    shapes&.each(&:release)
    child&.release
  end
end
