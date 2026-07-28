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
    expect { body.interpolated(0.5) }.to raise_error(Jolt::UseAfterDestroyError)
    expect(@system.bodies.size).to eq(0)
  end

  it "rejects access from another thread during a native operation" do
    entered = Queue.new
    release = Queue.new
    owner = Thread.new do
      @system.__with_native_operation do
        entered << true
        release.pop
      end
    end
    entered.pop

    expect { @system.gravity }.to raise_error(Jolt::ConcurrentAccessError)
    expect { @system.update(1.0 / 60.0) }.to raise_error(Jolt::ConcurrentAccessError)
    expect { @system.destroy }.to raise_error(Jolt::ConcurrentAccessError)
  ensure
    release&.push(true)
    owner&.join
  end

  it "validates values before passing them to fixed-width native arguments" do
    expect do
      described_class.new(max_bodies: 1 << 32)
    end.to raise_error(Jolt::InvalidArgumentError, /32-bit/)
    expect do
      described_class.new(contact_queue_capacity: (1 << 30) + 1)
    end.to raise_error(Jolt::InvalidArgumentError, /contact_queue_capacity/)
    expect do
      @system.update(1.0 / 60.0, collision_steps: 1 << 31)
    end.to raise_error(Jolt::InvalidArgumentError, /32-bit/)
  end

  it "normalizes invalid motion values to an API error" do
    expect do
      @system.bodies.create(shape: Jolt::Shape.sphere(0.5), motion: nil)
    end.to raise_error(Jolt::InvalidArgumentError, /motion/)
  end

  it "destroys owned bodies and shapes with the system" do
    shape = Jolt::Shape.sphere(0.5)
    body = @system.bodies.create(shape:)

    @system.destroy

    expect(body).to be_destroyed
    expect(shape).to be_released
    expect { @system.gravity }.to raise_error(Jolt::UseAfterDestroyError)
  end

  it "raycasts closest bodies with an object-layer mask" do
    floor = @system.bodies.create(
      shape: Jolt::Shape.box([5, 0.5, 5]),
      position: [0, -0.5, 0],
      motion: :static
    )
    @system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [0, 2, 0])

    hit = @system.raycast(
      origin: [0, 5, 0],
      direction: [0, -10, 0],
      layer_mask: [:non_moving]
    )

    expect(hit.body).to eq(floor)
    expect(hit.point.to_a).to all(be_within(1e-6).of(0.0))
    expect(hit.normal.to_a).to eq([0.0, 1.0, 0.0])
  end

  it "copies contact events out of the native worker-thread queue" do
    floor = @system.bodies.create(
      shape: Jolt::Shape.box([5, 0.5, 5]),
      position: [0, -0.5, 0],
      motion: :static
    )
    ball = @system.bodies.create(shape: Jolt::Shape.sphere(0.5), position: [0, 2, 0])
    added = []

    60.times do
      @system.update(1.0 / 60.0)
      added.concat(@system.contact_events.added)
    end

    expect(added.length).to eq(1)
    expect([added.first.body_a, added.first.body_b]).to contain_exactly(floor, ball)
    expect(added.first.normal).to be_a(Larb::Vec3)
    expect(@system.contact_events.dropped_count).to eq(0)
  end

  it "prevents dynamic bodies from using static-only mesh shapes" do
    mesh = Jolt::Shape.mesh(
      vertices: [[0, 0, 0], [1, 0, 0], [0, 0, 1]],
      indices: [[0, 1, 2]]
    )

    expect do
      @system.bodies.create(shape: mesh)
    end.to raise_error(Jolt::InvalidArgumentError, /static bodies/)
  ensure
    mesh&.release
  end
end
