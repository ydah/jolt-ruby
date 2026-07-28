# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jolt::CharacterVirtual do
  before do
    @system = Jolt::System.new
    @system.bodies.create(
      shape: Jolt::Shape.box([5, 0.5, 5]),
      position: [0, -0.5, 0],
      motion: :static,
      layer: :non_moving
    )
    @character = described_class.new(
      @system,
      shape: Jolt::Shape.capsule(half_height: 0.8, radius: 0.3),
      position: [0, 2, 0]
    )
  end

  after do
    @system&.destroy
  end

  it "updates position, rotation, velocity and mass" do
    @character.position = [1, 3, 2]
    @character.rotation = [0, 0, 0, 1]
    @character.velocity = [0, -1, 0]
    @character.mass = 80
    @character.update(1.0 / 60)

    expect(@character.position.to_a).to all(be_a(Float))
    expect(@character.position.x).to be_within(0.01).of(1)
    expect(@character.rotation.w).to be_within(0.001).of(1)
    expect(@character.velocity.y).to be <= 0
    expect(@character.mass).to be_within(0.001).of(80)
    expect(%i[on_ground sliding in_air]).to include(@character.ground_state)
    expect([true, false]).to include(@character.supported?)
  end

  it "lands on static geometry" do
    180.times do
      velocity = @character.velocity
      @character.velocity = [velocity.x, velocity.y - (9.81 / 60), velocity.z]
      @system.update(1.0 / 60)
      @character.update(1.0 / 60)
    end

    expect(@character.position.y).to be_between(1.0, 1.2)
    expect(@character).to be_supported
    expect(@character.ground_state).to eq(:on_ground)
  end

  it "invalidates the handle on explicit or system destruction" do
    @character.destroy
    expect(@character).to be_destroyed
    expect { @character.position }.to raise_error(Jolt::UseAfterDestroyError)

    replacement = described_class.new(
      @system,
      shape: Jolt::Shape.sphere(0.5),
      position: [0, 2, 0]
    )
    @system.destroy
    expect(replacement).to be_destroyed
    expect { replacement.update(0.1) }.to raise_error(Jolt::UseAfterDestroyError)
  end

  it "rejects an invalid maximum slope" do
    shape = Jolt::Shape.sphere(0.5)

    expect do
      described_class.new(@system, shape:, max_slope: Math::PI)
    end.to raise_error(Jolt::InvalidArgumentError, /max_slope/)
  ensure
    shape&.release
  end
end
