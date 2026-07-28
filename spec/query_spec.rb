# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::SystemQueries do
  before do
    @system = Jolt::System.new
    @near = @system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [0, 0, 0])
    @far = @system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [20, 0, 0])
    @system.update(1.0 / 60)
  end

  after do
    @system&.destroy
  end

  it "returns and yields bodies overlapping a sphere" do
    yielded = []
    hits = @system.overlap_sphere([0, 0, 0], 1, layer_mask: :moving) do |body|
      yielded << body
    end

    expect(hits).to contain_exactly(@near)
    expect(yielded).to eq(hits)
  end

  it "returns bodies whose bounds contain a point" do
    expect(@system.overlap_point([0, 0, 0])).to contain_exactly(@near)
    expect(@system.overlap_point([10, 0, 0])).to be_empty
  end
end
