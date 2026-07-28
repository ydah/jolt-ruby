# frozen_string_literal: true

require "jolt"

begin
  system = Jolt::System.new
  system.bodies.create(
    shape: Jolt::Shape.box([10, 0.5, 10]),
    position: [0, -0.5, 0],
    motion: :static
  )
  character = Jolt::CharacterVirtual.new(
    system,
    shape: Jolt::Shape.capsule(half_height: 0.8, radius: 0.3),
    position: [0, 2, 0]
  )

  180.times do |frame|
    velocity = character.velocity
    character.velocity = [1, velocity.y - 9.81 / 60, 0]
    system.update(1.0 / 60)
    character.update(1.0 / 60)
    if (frame % 15).zero?
      puts format(
        "%3d  position=%s  ground=%s",
        frame,
        character.position.to_a.map { |value| value.round(3) },
        character.ground_state
      )
    end
  end
ensure
  system&.destroy
  Jolt.shutdown
end
