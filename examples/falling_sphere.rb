# frozen_string_literal: true

require "jolt"

begin
  system = Jolt::System.new
  system.bodies.create(
    shape: Jolt::Shape.box([10, 0.5, 10]),
    position: [0, -0.5, 0],
    motion: :static
  )
  ball = system.bodies.create(
    shape: Jolt::Shape.sphere(0.5),
    position: [0, 5, 0],
    restitution: 0.6
  )

  120.times do |frame|
    system.update(1.0 / 60)
    puts format("%3d  y=% .3f", frame, ball.position.y) if (frame % 10).zero?
  end
ensure
  system&.destroy
  Jolt.shutdown
end
