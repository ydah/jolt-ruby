# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::Constraint do
  around do |example|
    @system = Jolt::System.new
    shape = Jolt::Shape.box([0.5, 0.5, 0.5])
    @fixed_body = @system.bodies.create(shape:, position: [0, 2, 0], motion: :static)
    @moving_body = @system.bodies.create(shape:, position: [0, 1, 0])
    example.run
  ensure
    @system&.destroy
  end

  it "creates all basic two-body constraint types" do
    constraints = [
      @system.constraints.fixed(body_a: @fixed_body, body_b: @moving_body),
      @system.constraints.point(
        body_a: @fixed_body, body_b: @moving_body, anchor: [0, 1.5, 0]
      ),
      @system.constraints.distance(
        body_a: @fixed_body, body_b: @moving_body, limits: 0.5..2.0
      ),
      @system.constraints.hinge(
        body_a: @fixed_body, body_b: @moving_body,
        anchor: [0, 1.5, 0], limits: -0.5..0.5
      ),
      @system.constraints.slider(
        body_a: @fixed_body, body_b: @moving_body,
        anchor: [0, 1.5, 0], axis: [1, 0, 0], limits: -1.0..1.0
      )
    ]

    expect(constraints.map(&:kind)).to eq(%i[fixed point distance hinge slider])
    expect(constraints).to all(be_enabled)
    expect(@system.constraints.size).to eq(5)
  end

  it "updates limits and motor targets" do
    distance = @system.constraints.distance(
      body_a: @fixed_body, body_b: @moving_body, limits: 0.5..2.0
    )
    hinge = @system.constraints.hinge(
      body_a: @fixed_body, body_b: @moving_body, anchor: [0, 1.5, 0]
    )
    slider = @system.constraints.slider(
      body_a: @fixed_body, body_b: @moving_body,
      anchor: [0, 1.5, 0], axis: [1, 0, 0]
    )

    distance.limits = [0.25, 1.5]
    hinge.motor_speed = 2.0
    slider.limits = -2.0..2.0

    expect(distance.limits).to eq([0.25, 1.5])
    expect(hinge.motor_speed).to eq(2.0)
    expect(slider.limits).to eq([-2.0, 2.0])
  end

  it "destroys attached constraints before destroying a body" do
    constraint = @system.constraints.fixed(body_a: @fixed_body, body_b: @moving_body)

    @moving_body.destroy

    expect(constraint).to be_destroyed
    expect(@system.constraints.size).to eq(0)
    expect { constraint.enabled? }.to raise_error(Jolt::UseAfterDestroyError)
  end

  it "validates distance bodies before resolving default points" do
    expect do
      @system.constraints.distance(body_a: Object.new, body_b: @moving_body)
    end.to raise_error(Jolt::InvalidArgumentError, /constraint bodies/)
  end
end
