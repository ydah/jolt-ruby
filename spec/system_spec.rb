# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::System do
  around do |example|
    @system = described_class.new
    example.run
  ensure
    @system&.destroy
  end

  it "simulates a falling dynamic body" do
    ball = @system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [0, 5, 0])

    30.times { @system.update(1.0 / 60.0) }

    expect(ball.position.y).to be < 5.0
    expect(ball.linear_velocity.y).to be_within(0.15).of(-4.905)
  end

  it "supports body properties, impulses, and Ruby user data" do
    body = @system.bodies.create(
      shape: Jolt::Shape.box([0.5, 0.5, 0.5]),
      friction: 0.3,
      restitution: 0.7,
      user_data: {kind: :crate}
    )

    body.apply_impulse([2, 0, 0])

    expect(body.friction).to be_within(1e-6).of(0.3)
    expect(body.restitution).to be_within(1e-6).of(0.7)
    expect(body.user_data).to eq(kind: :crate)
    expect(body.linear_velocity.x).to be_positive
  end

  it "moves kinematic bodies and records interpolation transforms" do
    body = @system.bodies.create(
      shape: Jolt::Shape.sphere(0.5),
      motion: :kinematic,
      position: [0, 1, 0]
    )
    body.kinematic_move_to([2, 1, 0], [0, 0, 0, 1], 0.5)
    @system.update(0.25)

    transform = body.interpolated(0.5)
    expect(transform.position).to be_a(Larb::Vec3)
    expect(transform.rotation).to be_a(Larb::Quat)
  end

  it "invalidates body handles when explicitly destroyed" do
    body = @system.bodies.create(shape: Jolt::Shape.sphere(0.5))

    body.destroy

    expect(body).to be_destroyed
    expect { body.position }.to raise_error(Jolt::UseAfterDestroyError)
    expect(@system.bodies.size).to eq(0)
  end

  it "destroys owned bodies and shapes with the system" do
    shape = Jolt::Shape.sphere(0.5)
    body = @system.bodies.create(shape:)

    @system.destroy

    expect(body).to be_destroyed
    expect(shape).to be_released
    expect { @system.gravity }.to raise_error(Jolt::UseAfterDestroyError)
  end
end
