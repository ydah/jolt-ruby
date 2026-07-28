# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe "physics validity" do
  DETERMINISM_FIXTURE = JSON.parse(
    File.read(File.join(__dir__, "fixtures", "determinism.json"))
  ).freeze

  def with_system
    system = Jolt::System.new
    yield system
  ensure
    system&.destroy
  end

  def stack_snapshot(seed)
    with_system do |system|
      system.bodies.create(
        shape: Jolt::Shape.box([5, 0.5, 5]),
        position: [0, -0.5, 0],
        motion: :static
      )
      random = Random.new(seed)
      shape = Jolt::Shape.box([0.4, 0.4, 0.4])
      bodies = 100.times.map do |index|
        column = index % 25
        level = index / 25
        x = ((column % 5) - 2) * 0.9 + random.rand(-0.02..0.02)
        z = ((column / 5) - 2) * 0.9 + random.rand(-0.02..0.02)
        system.bodies.create(shape:, position: [x, 0.45 + level * 0.85, z])
      end
      180.times { system.update(1.0 / 120) }
      bodies.map { |body| body.position.to_a }
    end
  end

  it "matches the committed fixed-seed 100-body platform snapshot" do
    platform = Jolt::Native::Platform.tag
    snapshot_name = DETERMINISM_FIXTURE.fetch("platform_snapshots").fetch(platform)
    expected = DETERMINISM_FIXTURE.fetch("snapshots").fetch(snapshot_name)
    actual = stack_snapshot(12_345)
    tolerance = DETERMINISM_FIXTURE.fetch("tolerance")

    expect(actual.length).to eq(expected.length)
    actual.flatten.zip(expected.flatten).each_with_index do |(value, baseline), index|
      expect(value).to be_within(tolerance).of(baseline), "snapshot component #{index}"
    end
  end

  it "matches gravitational acceleration in free fall" do
    with_system do |system|
      body = system.bodies.create(
        shape: Jolt::Shape.sphere(0.5),
        position: [0, 10, 0],
        linear_damping: 0
      )
      60.times { system.update(1.0 / 60) }

      expect(body.linear_velocity.y).to be_within(1e-3).of(-9.81)
    end
  end

  it "returns to its release height with unit restitution" do
    with_system do |system|
      system.bodies.create(
        shape: Jolt::Shape.box([10, 0.5, 10]),
        position: [0, -0.5, 0],
        motion: :static,
        restitution: 1
      )
      body = system.bodies.create(
        shape: Jolt::Shape.sphere(0.5),
        position: [0, 5, 0],
        restitution: 1,
        linear_damping: 0,
        angular_damping: 0
      )

      bounced = false
      peak = 0.0
      300.times do
        system.update(1.0 / 120)
        bounced ||= body.linear_velocity.y.positive?
        peak = [peak, body.position.y].max if bounced
      end

      expect(bounced).to be(true)
      expect(peak).to be_within(0.05).of(5)
    end
  end

  it "holds above the static-friction slope threshold" do
    angle = 20 * Math::PI / 180
    rotation = [0, 0, Math.sin(angle / 2), Math.cos(angle / 2)]
    normal = [-Math.sin(angle), Math.cos(angle), 0]

    with_system do |system|
      system.bodies.create(
        shape: Jolt::Shape.box([5, 0.25, 2]),
        rotation:,
        motion: :static,
        friction: 1
      )
      body = system.bodies.create(
        shape: Jolt::Shape.box([0.25, 0.25, 0.25]),
        position: normal.map { |component| component * 0.5 },
        rotation:,
        friction: 1,
        linear_damping: 0,
        angular_damping: 0
      )
      start = body.position
      240.times { system.update(1.0 / 120) }

      expect(body.position.x).to be_within(0.02).of(start.x)
      expect(body.linear_velocity.length).to be < 1e-3
    end
  end
end
